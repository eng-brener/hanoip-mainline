// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * Experimental Moto G60 Ilitek ILI7807 SPI input driver.
 * Protocol/IRAM sequence derived from Ilitek's GPL ilitek_v3_mmi driver:
 * Copyright (C) 2011 ILI Technology Corporation.
 * Original author: Dicky Chiang <dicky_chiang@ilitek.com>
 *
 * Only the verified hanoip AP/DATA/TUNING image is accepted. No controller
 * flash programming, factory interfaces, filesystem writes or gestures.
 */
#include <linux/crc32.h>
#include <linux/delay.h>
#include <linux/firmware.h>
#include <linux/gpio/consumer.h>
#include <linux/input.h>
#include <linux/input/mt.h>
#include <linux/interrupt.h>
#include <linux/module.h>
#include <linux/spi/spi.h>
#include <linux/unaligned.h>

#define ILI_FIRMWARE "ilitek/hanoip-7807-iram.bin"
#define ILI_CHIP 0x7807
#define ILI_SLOTS 10
#define ILI_REPORT 43
#define ILI_CHUNK 2048
#define ILI_XFER (ILI_CHUNK + 8)
#define ILI_HEADER 40
#define ILI_ENTRY 20
#define ILI_BLOCKS 3

struct ili_hanoip {
	struct spi_device *spi;
	struct gpio_desc *reset;
	struct input_dev *input;
	u8 *tx, *rx;
	bool ice;
	unsigned long irqs, reports, rejected;
};

static int ili_transfer(struct ili_hanoip *ts, size_t txlen, size_t rxlen)
{
	size_t offset = ts->ice ? 1 : 3;
	size_t length = rxlen ? offset + rxlen : txlen;
	struct spi_transfer transfer = {
		.tx_buf = ts->tx,
		.rx_buf = rxlen ? ts->rx : NULL,
		.len = length,
	};
	int ret;

	if (length > ILI_XFER || txlen > length)
		return -EINVAL;
	memset(ts->tx + txlen, 0, length - txlen);
	ret = spi_sync_transfer(ts->spi, &transfer, 1);
	if (ret)
		return ret;
	if (rxlen && !ts->ice && ts->rx[1] != 0xa3)
		return -EIO;
	return 0;
}

static int ili_read(struct ili_hanoip *ts, void *data, size_t size)
{
	int ret;

	ts->tx[0] = 0x83;
	ret = ili_transfer(ts, 1, size);
	if (!ret)
		memcpy(data, ts->rx + (ts->ice ? 1 : 3), size);
	return ret;
}

static int ili_ice_control(struct ili_hanoip *ts, bool enable)
{
	int ret;

	ts->tx[0] = 0x82;
	ts->tx[1] = enable ? 0x25 : 0x1b;
	ts->tx[2] = 0x62;
	ts->tx[3] = 0x10;
	ts->tx[4] = 0x18;
	ret = ili_transfer(ts, 5, 0);
	if (!ret) {
		ts->ice = enable;
		usleep_range(1000, 2000);
	}
	return ret;
}

static int ili_ice_address(struct ili_hanoip *ts, u32 address)
{
	ts->tx[0] = 0x82;
	ts->tx[1] = 0x25;
	ts->tx[2] = address;
	ts->tx[3] = address >> 8;
	ts->tx[4] = address >> 16;
	return ili_transfer(ts, 5, 0);
}

static int ili_ice_read(struct ili_hanoip *ts, u32 address, void *data, size_t size)
{
	int ret = ili_ice_address(ts, address);

	return ret ? ret : ili_read(ts, data, size);
}

static int ili_ice_write(struct ili_hanoip *ts, u32 address,
			 const void *data, size_t size)
{
	if (size > ILI_CHUNK)
		return -EINVAL;
	ts->tx[0] = 0x82;
	ts->tx[1] = 0x25;
	ts->tx[2] = address;
	ts->tx[3] = address >> 8;
	ts->tx[4] = address >> 16;
	memcpy(ts->tx + 5, data, size);
	return ili_transfer(ts, size + 5, 0);
}

static int ili_command(struct ili_hanoip *ts, const u8 *data, size_t size)
{
	if (size > ILI_CHUNK)
		return -EINVAL;
	ts->tx[0] = 0x82;
	ts->tx[1] = size >> 8;
	ts->tx[2] = size;
	memcpy(ts->tx + 3, data, size);
	return ili_transfer(ts, size + 3, 0);
}

static int ili_validate_firmware(const struct firmware *fw)
{
	static const u32 destinations[] = { 0, 0x20870, 0x20670 };
	static const u32 sizes[] = { 0x14000, 0x2000, 0x200 };
	size_t offset = ILI_HEADER + ILI_BLOCKS * ILI_ENTRY;
	int i;

	if (fw->size < offset || memcmp(fw->data, "HNOIRAM1", 8) ||
	    get_unaligned_le32(fw->data + 8) != ILI_CHIP ||
	    get_unaligned_le32(fw->data + 12) != ILI_BLOCKS ||
	    get_unaligned_le32(fw->data + 16) != 1080 ||
	    get_unaligned_le32(fw->data + 20) != 2460 ||
	    get_unaligned_le32(fw->data + 24) != 2048 ||
	    get_unaligned_le32(fw->data + 28) != 0x10000a00 ||
	    get_unaligned_le32(fw->data + 32) != 0x01040608 ||
	    get_unaligned_le32(fw->data + 36) != 0)
		return -EINVAL;
	for (i = 0; i < ILI_BLOCKS; i++) {
		const u8 *entry = fw->data + ILI_HEADER + i * ILI_ENTRY;
		u32 size = get_unaligned_le32(entry + 8);
		u32 crc = get_unaligned_le32(entry + 12);

		if (get_unaligned_le32(entry) != i + 1 ||
		    get_unaligned_le32(entry + 4) != destinations[i] ||
		    size != sizes[i] || get_unaligned_le32(entry + 16) != offset ||
		    size > fw->size - offset)
			return -EINVAL;
		if (crc32_be(~0U, fw->data + offset, size - 4) != crc ||
		    get_unaligned_be32(fw->data + offset + size - 4) != crc)
			return -EBADMSG;
		offset += size;
	}
	return offset == fw->size ? 0 : -EINVAL;
}

static int ili_load_iram(struct ili_hanoip *ts, const struct firmware *fw)
{
	u8 verify[256], pid[4], code_reset = 0xae;
	int i, ret;

	/* GPIO_ACTIVE_LOW: high 1 ms, low 5 ms, high 10 ms. */
	gpiod_set_value_cansleep(ts->reset, 0);
	usleep_range(1000, 2000);
	gpiod_set_value_cansleep(ts->reset, 1);
	usleep_range(5000, 6000);
	gpiod_set_value_cansleep(ts->reset, 0);
	usleep_range(10000, 11000);
	ret = ili_ice_control(ts, true);
	if (ret)
		return ret;
	ret = ili_ice_read(ts, 0x4009c, pid, sizeof(pid));
	if (ret)
		goto out;
	dev_info(&ts->spi->dev, "Ilitek PID %#08x\n", get_unaligned_le32(pid));
	if (get_unaligned_le32(pid) >> 16 != ILI_CHIP) {
		ret = -ENODEV;
		goto out;
	}
	for (i = 0; i < ILI_BLOCKS; i++) {
		const u8 *entry = fw->data + ILI_HEADER + i * ILI_ENTRY;
		u32 address = get_unaligned_le32(entry + 4);
		u32 size = get_unaligned_le32(entry + 8);
		const u8 *data = fw->data + get_unaligned_le32(entry + 16);
		u32 done;

		for (done = 0; done < size; done += ILI_CHUNK) {
			ret = ili_ice_write(ts, address + done, data + done,
					    min_t(u32, ILI_CHUNK, size - done));
			if (ret)
				goto out;
		}
		/* Verify every downloaded byte, without touching flash/CRC registers. */
		for (done = 0; done < size; done += sizeof(verify)) {
			u32 count = min_t(u32, sizeof(verify), size - done);

			ret = ili_ice_read(ts, address + done, verify, count);
			if (ret)
				goto out;
			if (memcmp(verify, data + done, count)) {
				dev_err(&ts->spi->dev, "IRAM readback mismatch at %#x\n", address + done);
				ret = -EBADMSG;
				goto out;
			}
		}
		dev_info(&ts->spi->dev, "IRAM block %d: %u bytes verified at %#x\n",
			 i + 1, size, address);
	}
	ret = ili_ice_write(ts, 0x40040, &code_reset, 1);
out:
	if (ts->ice) {
		int exit_ret = ili_ice_control(ts, false);

		if (!ret)
			ret = exit_ret;
	}
	msleep(20);
	return ret;
}

static int ili_check_running_firmware(struct ili_hanoip *ts)
{
	const u8 pre[] = { 0xf6, 0x21 }, command = 0x21;
	const u8 demo[] = { 0xf0, 0x00 };
	u8 version[9];
	int ret;

	ret = ili_command(ts, pre, sizeof(pre));
	if (ret)
		return ret;
	usleep_range(1000, 2000);
	ret = ili_command(ts, &command, 1);
	if (ret)
		return ret;
	msleep(20);
	ret = ili_read(ts, version, sizeof(version));
	if (ret)
		return ret;
	dev_info(&ts->spi->dev, "FW response %*ph\n", (int)sizeof(version), version);
	if (version[0] != 0x21 || get_unaligned_be32(version + 1) != 0x10000a00)
		return -EBADMSG;
	ret = ili_command(ts, demo, sizeof(demo));
	msleep(20);
	return ret;
}

static irqreturn_t ili_irq(int irq, void *data)
{
	struct ili_hanoip *ts = data;
	u8 report[ILI_REPORT], checksum = 0;
	int i, ret;

	ts->irqs++;
	ret = ili_read(ts, report, sizeof(report));
	if (ret)
		goto reject;
	for (i = 0; i < sizeof(report); i++)
		checksum += report[i];
	if (checksum || report[0] != 0x5a)
		goto reject;
	/* Validate the complete frame before changing any input slots. */
	for (i = 0; i < ILI_SLOTS; i++) {
		const u8 *p = report + 1 + i * 4;
		unsigned int x = ((p[0] & 0xf0) << 4) | p[1];
		unsigned int y = ((p[0] & 0x0f) << 8) | p[2];

		if (p[0] == 0xff && p[1] == 0xff && p[2] == 0xff)
			continue;
		if (x >= 2048 || y >= 2048)
			goto reject;
	}
	for (i = 0; i < ILI_SLOTS; i++) {
		const u8 *p = report + 1 + i * 4;
		bool active = !(p[0] == 0xff && p[1] == 0xff && p[2] == 0xff);

		input_mt_slot(ts->input, i);
		input_mt_report_slot_state(ts->input, MT_TOOL_FINGER, active);
		if (active) {
			unsigned int x = (((p[0] & 0xf0) << 4) | p[1]) * 1080 / 2048;
			unsigned int y = (((p[0] & 0x0f) << 8) | p[2]) * 2460 / 2048;

			input_report_abs(ts->input, ABS_MT_POSITION_X, x);
			input_report_abs(ts->input, ABS_MT_POSITION_Y, y);
		}
	}
	input_mt_sync_frame(ts->input);
	input_sync(ts->input);
	ts->reports++;
	return IRQ_HANDLED;
reject:
	ts->rejected++;
	return IRQ_HANDLED;
}

static ssize_t stats_show(struct device *dev, struct device_attribute *attr, char *buf)
{
	struct ili_hanoip *ts = spi_get_drvdata(to_spi_device(dev));

	return sysfs_emit(buf, "irqs=%lu reports=%lu rejected=%lu\n",
			 READ_ONCE(ts->irqs), READ_ONCE(ts->reports), READ_ONCE(ts->rejected));
}
static DEVICE_ATTR_RO(stats);
static struct attribute *ili_attrs[] = { &dev_attr_stats.attr, NULL };
ATTRIBUTE_GROUPS(ili);

static int ili_probe(struct spi_device *spi)
{
	struct device *dev = &spi->dev;
	const struct firmware *fw;
	struct ili_hanoip *ts;
	int ret;

	if (spi->irq <= 0)
		return dev_err_probe(dev, -EINVAL, "Missing touch IRQ\n");
	ts = devm_kzalloc(dev, sizeof(*ts), GFP_KERNEL);
	if (!ts)
		return -ENOMEM;
	ts->tx = devm_kzalloc(dev, ILI_XFER, GFP_KERNEL);
	ts->rx = devm_kzalloc(dev, ILI_XFER, GFP_KERNEL);
	if (!ts->tx || !ts->rx)
		return -ENOMEM;
	ts->spi = spi;
	spi_set_drvdata(spi, ts);
	spi->mode = SPI_MODE_0;
	spi->bits_per_word = 8;
	spi->max_speed_hz = min(spi->max_speed_hz, 10000000U);
	ret = spi_setup(spi);
	if (ret)
		return dev_err_probe(dev, ret, "SPI setup failed\n");
	ret = request_firmware(&fw, ILI_FIRMWARE, dev);
	if (ret)
		return dev_err_probe(dev, ret, "Missing RAM firmware\n");
	ret = ili_validate_firmware(fw);
	if (ret)
		goto release;
	ts->reset = devm_gpiod_get(dev, "reset", GPIOD_OUT_LOW);
	if (IS_ERR(ts->reset)) {
		ret = PTR_ERR(ts->reset);
		goto release;
	}
	ret = ili_load_iram(ts, fw);
release:
	release_firmware(fw);
	if (ret)
		return dev_err_probe(dev, ret, "IRAM initialization failed\n");
	ret = ili_check_running_firmware(ts);
	if (ret)
		return dev_err_probe(dev, ret, "Running firmware check failed\n");
	ts->input = devm_input_allocate_device(dev);
	if (!ts->input)
		return -ENOMEM;
	ts->input->name = "Hanoip Ilitek ILI7807 SPI";
	ts->input->id.bustype = BUS_SPI;
	input_set_abs_params(ts->input, ABS_MT_POSITION_X, 0, 1079, 0, 0);
	input_set_abs_params(ts->input, ABS_MT_POSITION_Y, 0, 2459, 0, 0);
	ret = input_mt_init_slots(ts->input, ILI_SLOTS, INPUT_MT_DIRECT);
	if (ret)
		return ret;
	ret = input_register_device(ts->input);
	if (ret)
		return ret;
	ret = devm_request_threaded_irq(dev, spi->irq, NULL, ili_irq,
				       IRQF_ONESHOT | IRQF_TRIGGER_FALLING, dev_name(dev), ts);
	if (ret)
		return dev_err_probe(dev, ret, "Touch IRQ setup failed\n");
	dev_info(dev, "ILI7807 ready: 1080x2460, 10 slots, IRAM only\n");
	return 0;
}

static const struct of_device_id ili_of_match[] = {
	{ .compatible = "tchip,ilitek" },
	{ }
};
MODULE_DEVICE_TABLE(of, ili_of_match);

static const struct spi_device_id ili_ids[] = { { "ilitek", 0 }, { } };
MODULE_DEVICE_TABLE(spi, ili_ids);

static struct spi_driver ili_driver = {
	.driver = {
		.name = "hanoip-ilitek-spi",
		.of_match_table = ili_of_match,
		.dev_groups = ili_groups,
	},
	.probe = ili_probe,
	.id_table = ili_ids,
};
module_spi_driver(ili_driver);
MODULE_FIRMWARE(ILI_FIRMWARE);
MODULE_DESCRIPTION("Hanoip Ilitek ILI7807 SPI input with verified RAM-only firmware");
MODULE_LICENSE("GPL");

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/sysmacros.h>
#include "libudev.h"

struct udev { int unused; };
struct udev_device { char syspath[128]; char value[128]; };

struct udev *udev_new(void) { return calloc(1, sizeof(struct udev)); }
struct udev *udev_unref(struct udev *udev) { free(udev); return NULL; }

struct udev_device *udev_device_new_from_devnum(struct udev *udev, char type, dev_t devnum)
{
	struct udev_device *dev;

	if (!udev || type != 'c')
		return NULL;
	dev = calloc(1, sizeof(*dev));
	if (!dev)
		return NULL;
	snprintf(dev->syspath, sizeof(dev->syspath), "/sys/dev/char/%u:%u",
		 major(devnum), minor(devnum));
	return dev;
}

const char *udev_device_get_sysattr_value(struct udev_device *dev, const char *sysattr)
{
	char path[256];
	FILE *f;
	size_t n;

	snprintf(path, sizeof(path), "%s/%s", dev->syspath, sysattr);
	f = fopen(path, "r");
	if (!f)
		return NULL;
	n = fread(dev->value, 1, sizeof(dev->value) - 1, f);
	fclose(f);
	dev->value[n] = '\0';
	while (n && (dev->value[n - 1] == '\n' || dev->value[n - 1] == ' '))
		dev->value[--n] = '\0';
	return dev->value;
}

struct udev_device *udev_device_unref(struct udev_device *dev) { free(dev); return NULL; }

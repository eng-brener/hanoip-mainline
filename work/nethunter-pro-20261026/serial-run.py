import os,re,select,sys,termios,time
import glob
P=(glob.glob('/dev/cu.usbmodem*') or ['/dev/cu.usbmodem211401'])[0]
cmd=sys.argv[1]; wait=float(sys.argv[2]) if len(sys.argv)>2 else 6
fd=os.open(P,os.O_RDWR|os.O_NOCTTY|os.O_NONBLOCK)
a=termios.tcgetattr(fd); a[0]=0;a[1]=0;a[3]=0;a[4]=a[5]=termios.B115200
termios.tcsetattr(fd,termios.TCSANOW,a)
def pump(t):
    out=b''; end=time.time()+t
    while time.time()<end:
        r,_,_=select.select([fd],[],[],0.2)
        if not r: continue
        try: d=os.read(fd,65536)
        except OSError: return out
        if not d: return out
        out+=d
    return out
buf=pump(0.4)
os.write(fd,b'\r'); buf+=pump(0.8)
if b'login:' in buf:
    os.write(fd,b'kali\r'); buf+=pump(1.2)
    os.write(fd,b'1234\r'); buf+=pump(2.0)
os.write(fd,b'echo ==BEGIN==\r'); buf+=pump(0.8)
os.write(fd,cmd.encode()+b'\r')
buf+=pump(wait)
os.close(fd)
t=buf.decode(errors='replace')
t=re.sub(r'\x1b\][^\x07\x1b]*(\x07|\x1b\\)','',t)
t=''.join(c for c in t if c in '\n\t' or 32<=ord(c)<127)
i=t.find('==BEGIN==')
print(t[i:] if i>=0 else t[-1500:])

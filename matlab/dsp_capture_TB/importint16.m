function data = importint16(filename,rows)

fd = fopen(filename,'r');
data=int16(fread(fd,[rows,inf],'int16',0,'b'));
fclose(fd);


function data = importUint64(filename,rows)

fd = fopen(filename,'r');
data=uint64(fread(fd,[rows,inf],'uint64',0,'l'));
fclose(fd);


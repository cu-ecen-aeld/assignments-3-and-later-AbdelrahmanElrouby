#include <syslog.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h> 
#include <errno.h>
#include <unistd.h> 
#include <string.h>

int main(int argc, char *argv[])
{
    openlog(NULL,0,LOG_USER);

    if(argc != 3) 
    {
        syslog(LOG_ERR,"Invalid Number of arguments: %d",argc);
        return 1;
    }
    int fd = open(argv[1], O_RDWR | O_CREAT | O_APPEND, S_IRWXU);
    if (fd == -1) 
    {
        syslog(LOG_ERR,"Error opening file");
        return 1;
    }
    syslog(LOG_DEBUG,"Writing %s to %s",argv[2],argv[1]);
    ssize_t bytesWritten = write(fd, argv[2],strlen(argv[2])) ;
    if (bytesWritten == -1) {
        syslog(LOG_ERR,"Error writing to file");
        close(fd);
        return 1;
    }
    close(fd);
}
#include <stdio.h>
#include <string.h>
#include <syslog.h>

int find(int , char* []);
typedef enum {SUCCESS, NO_FULLPATH,NO_WRITE_STRING, FILE_OPEN_ERROR} ErrorType;
const char* error_messages[] = {"Success!","Missing Full Path Argument!", "Missing writeString Argument!","Unable to open File!"};

int main(int argc, char *argv[])
{
  return find(argc, argv);
}

int find(int argc, char* argv[])
{
  ErrorType ec = SUCCESS; // error_code
  openlog(0, LOG_CONS, LOG_USER);
  const char* fullpath = argc > 1? argv[1]: "\0"; 
  const char* textToWrite = argc > 2? argv[2]: "\0";

  syslog(LOG_DEBUG,"argc= %d fullpath= %s textToWrite= %s", argc, fullpath, textToWrite);

  if(strlen(fullpath) < 3)
  {
    ec = NO_FULLPATH;
  }
  else if(strlen(textToWrite) < 3)
  {
    ec = NO_WRITE_STRING;
  }
  else
  {
    syslog(LOG_DEBUG,"Will attempt to write %s into %s", textToWrite, fullpath);
    FILE* fp = fopen(fullpath,"a");
    if(fp == 0)
    {
      ec = FILE_OPEN_ERROR;
    }
    else
    {
      fprintf(fp, "%s",textToWrite);
      fclose(fp);
    }
  }

  if(ec)
  {
    syslog(LOG_ERR,"%s", error_messages[ec]);
    closelog();
    return 1;
  }
  closelog();
  return 0;
}


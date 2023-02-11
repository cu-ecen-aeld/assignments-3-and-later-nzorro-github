#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)
#define ms_to_ns(time) (1e6 * time)

void sleep_ms(long ms)
{
    nanosleep(&(struct timespec){.tv_nsec=ms_to_ns(ms)}, NULL); // sleep millisecs
}

void* threadfunc(void* thread_param)
{

    // TODO: wait, obtain mutex, wait, release mutex as described by thread_data structure
    // hint: use a cast like the one below to obtain thread arguments from your parameter
    struct thread_data* thread_func_args = (struct thread_data *) thread_param;
    if(thread_func_args != NULL)
    {
        sleep_ms(thread_func_args->wait_to_obtain_ms);
        pthread_mutex_lock(thread_func_args->data_mutex_ptr);
        if(thread_func_args->message != NULL)
        {
           DEBUG_LOG(thread_func_args->message);
        }
        sleep_ms(thread_func_args->wait_to_release_ms); // sleep millisecs
        pthread_mutex_unlock(thread_func_args->data_mutex_ptr);
    }
    else
    {
        ERROR_LOG("thread_func is NULL!");
    }
    return thread_param;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    /**
     * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
     * using threadfunc() as entry point.
     *
     * return true if successful.
     *
     * See implementation details in threading.h file comment block
     */

    if(thread != NULL)
    {
        struct thread_data * data_block = (struct thread_data *) malloc(sizeof(struct thread_data ) );
        if(data_block != NULL)
        {
            // data_block->thread_complete_success = false;  
            char* message = "Thread Function Executing Successfully\n";
            data_block->wait_to_obtain_ms = wait_to_obtain_ms;
            data_block->wait_to_release_ms = wait_to_release_ms;
            data_block->data_mutex_ptr = mutex;
            data_block->message = message;
            data_block->thread_complete_success = true;
            pthread_create(thread, NULL, threadfunc, (void *) data_block);
            return true;
            
        }
        else
        {
            ERROR_LOG("Data block allocation problem!\n");
        }
    }
    ERROR_LOG("Thread pointer allocation Eror!");
    return false;
}


#ifndef LIBTICKET_MUTEX_H_
#define LIBTICKET_MUTEX_H_

#include <pthread.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdatomic.h>

#define TICKET_MUTEX_DEFAULT_WAIT_TIMEOUT_MS 1000

// DON'T TOUCH ANY FIELDS IN THIS STRUCT! Treat it as an opaque struct.
// This struct is only exposed so that it could be statically allocated.
struct ticket_mutex {
	pthread_cond_t condition;
	pthread_mutex_t mutex;
	_Atomic(uint64_t) head;
	_Atomic(uint64_t) tail;
	_Atomic(uint32_t) generation;

	uint32_t wait_timeout_ms;
};

struct ticket_mutex_options {
	// Will the mutex be used between multiple processess?
	//
	// For more details check the documentation for `PTHREAD_PROCESS_SHARED`
	bool process_shared;

	// Should the mutex be able to recover from a crash?
	// Useful for when a mutex is shared between processess.
	//
	// For more details check the documentation for `PTHREAD_MUTEX_ROBUST`
	bool robust;

	// How frequently (in milliseconds) should `ticket_mutex_lock` check if the mutex owner died.
	//
	// Default value is `TICKET_MUTEX_DEFAULT_WAIT_TIMEOUT_MS`
	//
	// Depending on the use case, this can be increased for tasks where the mutex stays locked for a long time.
	//
	// Higher timeout values lower contention on the mutex, this can speed up lock acquisition in high
	// contention situations.
	uint32_t wait_timeout_ms;
};

// This function is NOT thread safe
//
// The behavior is undefined if called using an initialized mutex.
//
// Returns non-zero value on error
int ticket_mutex_init(struct ticket_mutex *mutex, struct ticket_mutex_options options);

// This function is NOT thread safe
//
// The behavior is undefined if called using an deinitialized mutex.
//
// The behavior is undefined if called while mutex is locked.
//
// Returns non-zero value on error
int ticket_mutex_deinit(struct ticket_mutex *mutex);

// This function is thread safe
//
// Returns non-zero value on error
int ticket_mutex_lock(struct ticket_mutex *mutex);

// This function is thread safe
//
// Returns non-zero value on error
int ticket_mutex_unlock(struct ticket_mutex *mutex);

// This function is thread safe
//
// Does not try to acquire the lock.
//
// Beware of Time-of-check to time-of-use (TOC/TOU) bugs.
// Don't rely on the results of this function for synchronization.
//
// Returns true is there is anybody inside the critical section.
// i.e. Called `ticket_mutex_lock`, but haven't yet called `ticket_mutex_unlock`
bool ticket_mutex_is_locked(struct ticket_mutex *mutex);

#endif //LIBTICKET_MUTEX_H_

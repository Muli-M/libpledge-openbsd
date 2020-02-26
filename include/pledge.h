#ifdef __linux__
#include <stdint.h> /* for uint64_t */
#include <linux/filter.h> /* for sock_fprog */
#endif

#define PLEDGED         0x1000000000000000ULL
#define PLEDGE_ALWAYS   0xffffffffffffffffULL
#define PLEDGE_DEBUG    0x0000000000000001ULL
#define PLEDGE_VERBOSE  0x0000000000000002ULL
#define PLEDGE_IOCTL    0x0000000000000010ULL
#define PLEDGE_RPATH    0x0000000000000020ULL
#define PLEDGE_WPATH    0x0000000000000040ULL
#define PLEDGE_CPATH    0x0000000000000080ULL
#define PLEDGE_STDIO    0x0000000000000100ULL
#define PLEDGE_CHOWN    0x0000000000000200ULL
#define PLEDGE_DPATH    0x0000000000000400ULL
#define PLEDGE_DRM      0x0000000000000800ULL
#define PLEDGE_EXEC     0x0000000000001000ULL
#define PLEDGE_FATTR    0x0000000000002000ULL
#define PLEDGE_FLOCK    0x0000000000004000ULL
#define PLEDGE_GETPW    0x0000000000008000ULL
#define PLEDGE_INET     0x0000000000010000ULL
#define PLEDGE_PROC     0x0000000000020000ULL
#define PLEDGE_ID       0x0000000000040000ULL
#define PLEDGE_SETTIME  0x0000000000080000ULL
#define PLEDGE_UNIX     0x0000000000100000ULL
#define PLEDGE_CHOWNUID 0x0000000000200000ULL
#define PLEDGE_EMUL     0x0000000000400000ULL
#define PLEDGE_IPC      0x0000000000800000ULL
#define PLEDGE_MOUNT    0x0000000001000000ULL
#define PLEDGE_KEY      0x0000000002000000ULL
#define PLEDGE_KERN     0x0000000004000000ULL

#define FILTER_WHITELIST 1
#define FILTER_BLACKLIST 2

#define _FLAG_DROPPED(x) \
	((oldflags&(x)) && (~flags&(x)))

#define _FILTER_OPEN \
	(!oldflags && !(flags&PLEDGE_CPATH)) || _FLAG_DROPPED(PLEDGE_CPATH) \
	? FILTER_BLACKLIST \
	: 0

#define _FILTER_CHOWN \
	(!oldflags && !(flags&PLEDGE_CHOWNUID)) \
	? FILTER_WHITELIST \
	: 0

#define _FILTER_PRCTL \
	(oldflags && !(flags&PLEDGE_PROC)) || (!oldflags && !(flags&PLEDGE_PROC)) \
	? FILTER_WHITELIST \
	: 0

#define _FILTER_SOCKET \
	(!oldflags && !(flags&PLEDGE_INET)^!(flags&PLEDGE_UNIX)) \
	? FILTER_WHITELIST \
	: _FLAG_DROPPED(PLEDGE_INET) ^ _FLAG_DROPPED(PLEDGE_UNIX) \
	? FILTER_WHITELIST \
	: 0

#define _FILTER_KILL \
	(!oldflags && !(flags&PLEDGE_PROC)) || _FLAG_DROPPED(PLEDGE_PROC) \
	? FILTER_WHITELIST \
	: 0

#define _FILTER_FCNTL \
	!(oldflags && flags&PLEDGE_PROC) || _FLAG_DROPPED(PLEDGE_PROC) \
	? FILTER_WHITELIST \
	: 0

#define _FILTER_IOCTL_ALWAYS \
	!oldflags || _FLAG_DROPPED(PLEDGE_IOCTL) \
	? FILTER_WHITELIST \
	: 0

#define _FILTER_IOCTL_IOCTL \
	(!oldflags && (flags&PLEDGE_IOCTL)) \
	? FILTER_WHITELIST \
	: _FLAG_DROPPED(PLEDGE_IOCTL) \
	? FILTER_BLACKLIST \
	: 0

struct sock_fprog *pledge_whitelist(uint64_t);
struct sock_fprog *pledge_blacklist(uint64_t, uint64_t);
struct sock_fprog *pledge_filter(uint64_t, uint64_t);
uint64_t pledge_flags(const char *);
int pledge(const char *, const char *[]);

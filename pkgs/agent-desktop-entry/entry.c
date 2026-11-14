#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char **argv) {
    if (argc != 3 || strcmp(argv[1], "-c") || strcmp(argv[2], "agent-desktop-entry")) {
        fputs("invalid entry invocation\n", stderr);
        return 126;
    }
    const char *request_env = getenv("SSH_ORIGINAL_COMMAND");
    const char *term_env = getenv("TERM");
    char *request = strdup(request_env ? request_env : "");
    char *term = strdup(term_env ? term_env : "");
    if (!request || !term || clearenv() || chdir("@homeDirectory@")) {
        fputs("entry initialization failed\n", stderr);
        return 126;
    }
    execl("@bashPath@", "bash", "--noprofile", "--norc", "@dispatcherPath@", request, term, (char *) NULL);
    perror("entry dispatcher");
    return 126;
}

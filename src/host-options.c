/*
 * This file is part of mod-host.
 *
 * mod-host is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * mod-host is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with mod-host.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

/*
************************************************************************************************************************
*
************************************************************************************************************************
*/


/*
************************************************************************************************************************
*           INCLUDE FILES
************************************************************************************************************************
*/

#include <getopt.h>
#include <stdlib.h>

#include "host-options.h"
#include "mod-host.h"


/*
************************************************************************************************************************
*           GLOBAL FUNCTIONS
************************************************************************************************************************
*/

int host_options_parse(int argc, char **argv, int accepted, host_options_t *options)
{
    static const struct option all_options[] = {
#ifndef _WIN32
        {"nofork", no_argument, 0, 'n'},
#endif
        {"verbose", no_argument, 0, 'v'},
        {"socket-port", required_argument, 0, 'p'},
        {"feedback-port", required_argument, 0, 'f'},
        {"interactive", no_argument, 0, 'i'},
        {"self-test", no_argument, 0, 't'},
        {"version", no_argument, 0, 'V'},
        {"help", no_argument, 0, 'h'},
        {0, 0, 0, 0}
    };

    struct option long_options[sizeof(all_options) / sizeof(all_options[0])];
    int opt, opt_index = 0, n = 0;
    unsigned i;

    for (i = 0; all_options[i].name; i++)
    {
        if (all_options[i].val == 'i' && !(accepted & HOST_OPTIONS_INTERACTIVE))
            continue;
        if (all_options[i].val == 't' && !(accepted & HOST_OPTIONS_SELF_TEST))
            continue;
        long_options[n++] = all_options[i];
    }
    long_options[n] = all_options[i];

    options->nofork = 0;
    options->verbose = 0;
    options->interactive = 0;
    options->selftest = 0;
    options->socket_port = SOCKET_DEFAULT_PORT;
    options->feedback_port = 0;

    while ((opt = getopt_long(argc, argv, (accepted & HOST_OPTIONS_INTERACTIVE) ? "nvp:f:iVh" : "nvp:f:Vh",
                              long_options, &opt_index)) != -1)
    {
        switch (opt)
        {
            case 'n':
                options->nofork = 1;
                break;

            case 'v':
                options->verbose = 1;
                options->nofork = 1;
                break;

            case 'p':
                options->socket_port = atoi(optarg);
                break;

            case 'f':
                options->feedback_port = atoi(optarg);
                break;

            case 'i':
                options->interactive = 1;
                options->nofork = 1;
                break;

            case 't':
                options->selftest = 1;
                break;

            case 'V':
            case 'h':
                return opt;
        }
    }

    return 0;
}

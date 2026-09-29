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

#ifndef HOST_OPTIONS_H
#define HOST_OPTIONS_H


/*
************************************************************************************************************************
*           CONFIGURATION DEFINES
************************************************************************************************************************
*/

/* The switches only some hosts take; the others are common to every host */
#define HOST_OPTIONS_INTERACTIVE    (1 << 0)
#define HOST_OPTIONS_SELF_TEST      (1 << 1)


/*
************************************************************************************************************************
*           DATA TYPES
************************************************************************************************************************
*/

typedef struct HOST_OPTIONS_T {
    int nofork;
    int verbose;
    int interactive;
    int selftest;
    int socket_port;
    int feedback_port;
} host_options_t;


/*
************************************************************************************************************************
*           FUNCTION PROTOTYPES
************************************************************************************************************************
*/

/* Parses the command line every host is started with: -n, -v, -p <port>, -f <port>, -V and -h, plus
   -i and --self-test when 'accepted' has them. Returns 0 to run, or 'V' or 'h' when the version or
   the help was asked for, which the caller prints. */
int host_options_parse(int argc, char **argv, int accepted, host_options_t *options);


/*
************************************************************************************************************************
*           END HEADER
************************************************************************************************************************
*/

#endif

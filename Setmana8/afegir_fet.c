#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <string.h>
#include <pwd.h>

#define LOG_FILE "/home/techsoft/fet.log"

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Ús: %s <text>\n", argv[0]);
        return EXIT_FAILURE;
    }

    FILE *file = fopen(LOG_FILE, "a");
    if (!file) {
        perror("No es pot obrir el fitxer de registre");
        return EXIT_FAILURE;
    }

    // Obtenir la data actual
    time_t t = time(NULL);
    struct tm *tm_info = localtime(&t);
    char date[20];
    strftime(date, sizeof(date), "%Y-%m-%d %H:%M:%S", tm_info);

    // Obtenir l'usuari actual
    uid_t uid = getuid();
    struct passwd *pw = getpwuid(uid);
    const char *username = pw ? pw->pw_name : "desconegut";

    // Escriure al fitxer de registre
    fprintf(file, "%s - %s - %s\n", date, username, argv[1]);
    fclose(file);

    return EXIT_SUCCESS;
}

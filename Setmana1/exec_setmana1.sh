#!/bin/bash

#
#   Test to 'comprovar_paquet'
#

#
# Test_0: Check what happens if you don't write any param to the script
# Exit: Should be a sentence reccomend what to write
#
test_0_paquets(){
    ./comprovar_paquet.sh
}

#
# Test_1: Test passing by param some packages that are already installed.
# Exit: Should write the packages are Installed
#

test_1_paquets(){
    packages=("cpio" "acct" "libtcl8.5" "dialog")

    ./comprovar_paquet.sh "${packages[@]}"
}

#
# Test_2: Test passing by param some packages that don't exist
#         Accept/Refuse and Check all the instalations
#         Remove all the new installations to test again this test
# Exit: All the new packages has to be successful for all the packages the user accept the installations
#       Execute again with the same packages saying they are already installed
#       Successful removed all the new packages
#

test_2_paquets(){
    packages=("zplug" "tcvt" "libsleef3" "cvsgraph")
    echo "Installing Packages (Accept/Refuse)"
    ./comprovar_paquet.sh "${packages[@]}"

    echo "Check if are installed"
    ./comprovar_paquet.sh "${packages[@]}"

    for package in "${packages[@]}"; do
        echo "Removing package: $package"
        sudo apt remove -y $package >> error.log 2>&1
        echo "Removed: $package"
    done

}

#
# Test_3: Try to install packages that do not exist, ACCEPTING all the instalations
# Exit: Sentence saying the package do not exist
#

test_3_paquets(){
    packages=("kdfsb" "38hhfww9" "dfdf432" "poopppp33333")
    ./comprovar_paquet.sh "${packages[@]}"
}

continue_testing(){
    local test="$1"
    echo "Actual Test: $test"
    echo "Press ENTER to continue the test, write 'q' if you want to quit."
    read -r answer

    if [[ "$answer" == "q" ]]; then
        return 1
    else
        return 0
    fi
}

test_Paquets(){
    if [ ! -f "error.log" ]; then
        touch "error.log"
    fi


    echo "*************************************"
    echo "*    TEST_Paquets 0: EMPTY PARAM    *"
    echo "*************************************"
    test_0_paquets
    echo ""

    echo "********************************************"
    echo "*    TEST_Paquets 1: PACKAGES INSTALLED    *"
    echo "********************************************"
    test_1_paquets
    echo ""

    echo "************************************************"
    echo "*    TEST_Paquets 2: PACKAGES NOT INSTALLED    *"
    echo "************************************************"
    test_2_paquets
    echo ""

    echo "***********************************************"
    echo "*    TEST_Paquets 3: PACKAGES NON-EXISTENT    *"
    echo "***********************************************"
    test_3_paquets
    echo ""
}


#
# Test: Test the monitoritzar_logs with no param input
# Exit: Should write output an error sentence and don't execute anything
#
test_monitoritzar_not_param(){
    ./monitoritzar_logs.sh
}

#
# Test: Check All the errors logs in the servcies that are runing
# Exit: Should write output the error logs the service had
#
# WARNING:  All the services have to be active
#           Check with: systemctl list-units --type=service --state=running
#
test_monitoritzar_existent_service(){
    
    services=("accounts-daemon" "acpid" "cron" "rsyslog"  "upower" "virtualbox-guest-utils")
    
    ./monitoritzar_logs.sh "${services[@]}"
}

#
# Test: Check All the errors logs with services that do not exist
# Exit: Should write the output: -- No entries --
#
test_monitoritzar_not_existent_service(){
    
    services=("ksjfks" "7437878" "lxsddd" "AAAAAAAA" "kslfslknd" "s7666")
    
    ./monitoritzar_logs.sh "${services[@]}"
}

#
# Test: Check All the errors logs in the servcies that are NOT runing
# Exit: Should write the output: -- No entries --
#
# WARNING:  All the services have to be inactive
#           Check with: systemctl list-units --type=service --state=running
#
test_monitoritzar_not_active(){
    
    services=("apache2" "mysql")
    
    ./monitoritzar_logs.sh "${services[@]}"
}

test_monitoritzar(){
    echo "**************************************"
    echo "*    TEST_Monitoritzar: NOT Param    *"
    echo "**************************************"
    test_monitoritzar_not_param
    echo ""

    echo "*********************************************"
    echo "*    TEST_Monitoritzar: Existent Service    *"
    echo "*********************************************"
    test_monitoritzar_existent_service
    echo ""

    echo "*************************************************"
    echo "*    TEST_Monitoritzar: NOT Existent Service    *"
    echo "*************************************************"
    test_monitoritzar_not_existent_service
    echo ""

    echo "***************************************"
    echo "*    TEST_Monitoritzar: NOT Active    *"
    echo "***************************************"
    test_monitoritzar_not_active
    echo ""
}


#
# Test: Test the missatge_logs with (no param, 1 param, 3 param) input
# Exit: Should write output an error sentence and don't execute anything
#
test_missatge_not_param(){
    ./missatge_logs.sh
    ./missatge_logs.sh "INFO"
    ./missatge_logs.sh "INFO" "Test sentence" "extra_param"
}

#
# Test: Show output with the sentence we wrote woth a level
# Exit: Should write the output the same sentence wrote and the command
#
# WARNING:  The output are gona increse the same time the test is executed
#
test_valid_missatge(){
    level=("INFO" "WARNING" "ERROR")
    sentence=("This sentence is to TEST MISSAGE LOG INFO" "This sentence is to TEST MISSAGE LOG WARNING" "This sentence is to TEST MISSAGE LOG ERROR")

    ./missatge_logs.sh "${level[0]}" "${sentence[0]}"
    ./missatge_logs.sh "${level[1]}" "${sentence[1]}"
    ./missatge_logs.sh "${level[2]}" "${sentence[2]}"
}

#
# Test: Show output with the sentence we wrote writing bad the level
# Exit: Should write the output the same sentence wrote and the command
#
# WARNING:  The output are gona increse the same time the test is executed
#
test_not_valid_missatge(){
    level=("sklfn" "11111" "AAAA")
    sentence=("This sentence is to TEST NOT MISSAGE LOG test1" "This sentence is to TEST NOT MISSAGE LOG test2" "This sentence is to TEST NOT MISSAGE LOG test3")

    ./missatge_logs.sh "${level[0]}" "${sentence[0]}"
    ./missatge_logs.sh "${level[1]}" "${sentence[1]}"
    ./missatge_logs.sh "${level[2]}" "${sentence[2]}"
}


test_missatge(){

    echo "*********************************"
    echo "*    TEST_Missatge: NOT Param   *"
    echo "*********************************"
    test_missatge_not_param
    echo ""

    echo "*****************************"
    echo "*    TEST_Missatge: Valid   *"
    echo "*****************************"
    test_valid_missatge
    echo ""

    echo "***********************************"
    echo "*    TEST_Missatge 0: NOT Valid   *"
    echo "***********************************"
    test_not_valid_missatge
    echo ""
    
}
test_backup(){
    # Define test directories and files
    test_dir="test_backup"
    backup_dir="Backups"
    backup_file="$backup_dir/backup_$(date +"%Y-%m-%d_%Hh-%Mm-%Ss").tgz"

    # Function to create the test environment
    create_enviroment() {
        echo "Creating test environment..."
        mkdir -p "$test_dir/subdir1" "$test_dir/subdir2"
        touch "$test_dir/archivo1.txt"
        touch "$test_dir/subdir1/archivo2.txt"
        touch "$test_dir/subdir2/archivo3.txt"
        touch "$test_dir/.archivo_oculto"
        touch "$test_dir/archivo_antiguo.txt"

        # Simulate an old file
        touch -d "2020-01-01 12:00:00" "$test_dir/archivo_antiguo.txt"

        # Create a read-only file
        touch "$test_dir/archivo_solo_lectura.txt"
        chmod 444 "$test_dir/archivo_solo_lectura.txt"

        # Create an executable script
        echo "echo 'Test script'" > "$test_dir/script.sh"
        chmod +x "$test_dir/script.sh"

        # Create a symbolic link
        ln -s "$test_dir/archivo1.txt" "$test_dir/enlace_simbolico"
    }

    # Clean up before running tests
    echo "Cleaning up previous test data..."
    rm -rf "$test_dir" "$backup_dir"
    echo ""

    # Run negative test cases
    echo "**************************************"
    echo "*    TEST_Backup 0: Invalid Cases    *"
    echo "**************************************"

    # Case 1: Backup a non-existing directory
    echo "** Testing non-existing directory... **"
    ./copia_seguretat.sh "Example_not_existent"
    echo ""

    # Case 2: Run without arguments
    echo "** Testing script without arguments... **"
    ./copia_seguretat.sh
    echo ""

    # Create test environment
    echo "******************************************"
    echo "*    TEST_Backup 1: Enviroment_Buckup    *"
    echo "******************************************"

    create_enviroment

    tree "$test_dir"
    echo ""

    # Run backup script
    echo "** Running backup script... **"
    ./copia_seguretat.sh "$test_dir"
    echo ""

    # Check if backup file exists
    echo "Verifying backup..."
    if [ -f "$backup_file" ]; then
        echo "Backup created successfully: $backup_file"
        echo ""
    else
        echo "ERROR: Backup file not found!"
        rm -rf "$test_dir"
        exit 1
    fi

    # Compare attributes after extracting the backup using comprova_copia.sh
    echo "** Verifying backup integrity with comprova_copia.sh... **"
    echo ""
    ./comprovar_copia.sh "$backup_file" "$test_dir"
    echo ""

    # Clean up test environment
    echo "Cleaning up test environment..."
    rm -rf "$test_dir"
    echo ""

    echo "All tests completed."
}


# TESTS
if continue_testing "Paquets"; then
    test_Paquets
fi

if continue_testing "Monitoritzar-Logs"; then
    test_monitoritzar
fi

if continue_testing "Missatge-Logs"; then
    test_missatge
fi

if continue_testing "Backup"; then
    test_backup
fi
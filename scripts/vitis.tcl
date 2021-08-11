# ************************************************
# Vitis project generation script
# A appeler depuis le dossier framework racine
# ************************************************

set ROOT        [pwd]
set PLATFORM    red_pitaya
set DOMAIN0     standalone_domain
set SYSTEM0     amp_system
set APP0        app0
set WORK        vitis

# setting the vitis workspace
setws [set WORK]

# platform project and boot files generation
platform create                                        \
    -name [set PLATFORM]                               \
    -hw [set ROOT]/vivado/design_1_wrapper.xsa         \
    -proc {ps7_cortexa9_0}                             \
    -os {standalone}                                   \
    -fsbl-target {psu_cortexa53_0}                     \
    -out [set ROOT]/[set WORK];

platform write
platform read [set ROOT]/[set WORK]/[set PLATFORM]/platform.spr
platform active [set PLATFORM]

importprojects [set WORK]/[set PLATFORM]
platform generate

# Create projet application + systeme
app create                          \
    -platform   [set PLATFORM]      \
    -name       [set APP0]          \
    -sysproj    [set SYSTEM0]       \
    -domain     [set DOMAIN0]       \
    -template "Empty Application" 

# Importing sources to the application
# importsources -name [set APP0] -path sw/main.c


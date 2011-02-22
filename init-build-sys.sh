#! /bin/bash
# $Id$
#
# Requires: Bash, gettext, and wmlxgettext (the Perl version)
#
# lbundle.py:
# http://websvn.kde.org/*checkout*/trunk/l10n-support/scripts/lbundle-check.py
#
# wmlxgettext (Perl):
# http://svn.gna.org/viewcvs/*checkout*/wesnoth/trunk/utils/wmlxgettext
#
# wmltrans.pm:
# http://svn.gna.org/viewcvs/*checkout*/wesnoth/trunk/utils/wmltrans.pm
#
#  Copyright © 2010, 2011 by Steven Panek <Majora700@gmail.com>
#  Part of the Wesnoth Campaign Translations project
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License version 2
#  or at your option any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY.
#
#  See the COPYING file for more details.
#

__CMDLINE=$*

# Spit out help
if [ "$1" = "" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
	cat <<- EOD
		Usage: init-build-sys.sh [options] [version] ADDON_DIRECTORY OUTPUT_DIRECTORY

		init-build-sys.sh generates the translation build system for addons as well as po files.

		ADDON_DIRECTORY represents the name of the directory that contains the targeted addon, while OUTPUT_DIRECTORY represents the directory where the "po" directory and a few other files belonging to the build system will be dumped.

		Options:

		--force         | -f       Overwrite files/directories normally created by this script, if any exist.
		--help          | -h       Displays this information and exits.
		--verbose       | -v       Enables extra information.

		Supported versions:

		--1.0
		--1.2
		--1.4
		--1.6
		--1.8
		--trunk

		Please note that 'support' for 1.0 and 1.2 is merely there for fun, thus we do not know if it truly works; if you find that what this script generates for 1.0/1.2 does not work, do not get mad.

		This script should be run in the directory that contains the target addon's directory.

		Report any issues to Espreon.
	EOD
	exit
fi

# Macros/whatevers that check for textdomain_check and textdomain_check_trunk
# Syntax: (name) () (url string)
need_thingy()
{
    echo "$1 was not found in your PATH; please put it in your PATH.

If you do not have $1, you can get it from here: $2"
    echo "Aborting..."
    exit 7
}

check_for_thingy()
{
    type -P $1 &>/dev/null || need_script $1 $2
}

need_perl_wmlxgettext()
{
    echo "The Perl version of wmlxgettext was not found in your PATH; please put it in your PATH.

If you do not have it, you can get it from here: http://svn.gna.org/viewcvs/*checkout*/wesnoth/trunk/utils/wmlxgettext"
    echo "Aborting..."
    exit 7
}

# Yes, I know that this is a bit hacky, but... yeahz...
check_for_perl_wmlxgettext()
{
    wmlxgettext | head -n 3 | grep "PACKAGE VERSION" > /dev/null || need_perl_wmlxgettext
}

# Checks to see if something the script is about to create exists; if that something exists, and if --force/-f is
# not enabled, abort
check_for_file()
{
    if [ -e "$MY_DIRECTORY/$1" ]; then
        if [ "${FORCE}" = "no" ]; then
            echo "File/directory '$1' exists; --force/-f not enabled; aborting..."
            exit 1
        fi
    fi
}

verbose_message()
{
    if [ "${VERBOSE}" = "yes" ]; then
       echo "VERBOSE: $1"
    fi
}

check_for_thingy "wmltrans.pm" "http://svn.gna.org/viewcvs/*checkout*/wesnoth/trunk/utils/wmltrans.pm"
check_for_perl_wmlxgettext
# check_for_thingy "lbundle-check.py" "http://websvn.kde.org/*checkout*/trunk/l10n-support/scripts/lbundle-check.py"

# Set some variables

# Find the location of this script and the directory that contains it
PATH_TO_ME=$(readlink -f $0)
MY_DIRECTORY="`dirname $PATH_TO_ME`"

# Disable verbosity by default
VERBOSE="no"

# Disable force by default
FORCE="no"

# Input/output
OUTPUT_DIRECTORY="null"
INPUT_DIRECTORY="null"

# Name of addon directory
ADDON_DIRECTORY_NAME="null"

# Version on which the target addon runs
VERSION="null"

# Parse parameters
while [ "${1}" != "" ] || [ "${1}" = "--help" ] || [ "${1}" = "-h" ]; do

    # Determine whether or not to enable force
    if [ "${1}" = "--force" ] || [ "${1}" = "-f" ]; then
        FORCE="yes"
        shift

    # Determine whether or not to enable more information
    elif [ "${1}" = "--verbose" ] || [ "${1}" = "-v" ]; then
        VERBOSE="yes"
        shift

    # Set version that the target addon uses
    # Yes, I am such a noob
    elif [ "${1}" = "--trunk" ]; then
        VERSION="trunk"
        shift

    elif [ "${1}" = "--1.8" ]; then
        VERSION="1.8"
        shift

    elif [ "${1}" = "--1.6" ]; then
        VERSION="1.6"
        shift

    elif [ "${1}" = "--1.4" ]; then
        VERSION="1.4"
        shift

    elif [ "${1}" = "--1.2" ]; then
        VERSION="1.2"
        shift

    elif [ "${1}" = "--1.0" ]; then
        VERSION="1.0"
        shift

    else

        # Assign the path to the current working directory to INITIAL_DIRECTORY
        INITIAL_DIRECTORY="${PWD}"

        # Assign the path of the input directory and the addon directory's name to variables
        cd ${1} && INPUT_DIRECTORY="$PWD" && ADDON_DIRECTORY_NAME="${1}"
        cd $INITIAL_DIRECTORY
        shift

        # Now, assign the path of the output directory to a variable
        # If the desired output directory does not exist...
        if ! [ -e "$1" ]; then
            verbose_message "'$1' does not exist... creating '$1'..."
            mkdir $1
        fi
        cd ${1} && OUTPUT_DIRECTORY="$PWD"
        cd $INITIAL_DIRECTORY
        shift
    fi
done

# Information enabled by --verbose/-v
if [ "${VERBOSE}" = "yes" ]; then
echo ""
echo "VERBOSE:"
echo "Version used by addon: $VERSION"
echo "Addon directory name: $ADDON_DIRECTORY_NAME"
echo "Input directory: $INPUT_DIRECTORY"
echo "Output directory: $OUTPUT_DIRECTORY"
echo "Path to script: $PATH_TO_ME"
echo "Path to directory that contains this script: $MY_DIRECTORY"

echo ""
fi

verbose_message "Including the 'lang-codes' file, which contains the language codes..."
# Include the file that contains the lang codes
source $MY_DIRECTORY/language-codes

# Move templates to the destination
echo ""
echo "Creating the build system in $OUTPUT_DIRECTORY..."

# Check to see if a 'po' directory already exists
check_for_file "$OUTPUT_DIRECTORY/po"

# Copy templates into /tmp for cleansing
verbose_message "Copying templates to /tmp/wescamp-build-sys-templates for cleansing..."
echo ""
cp -rf $MY_DIRECTORY/templates/ /tmp/wescamp-build-sys-templates

verbose_message "Entering /tmp/wescamp-build-sys/templates..."
echo ""
cd /tmp/wescamp-build-sys-templates/

# Cleanse the directories of '.svn' directories
verbose_message "Cleansing temporary directory of '.svn' directories..."
echo ""
rm -rf ./.svn

verbose_message "Entering /tmp/wescamp-build-sys-templates/po..."
echo ""
cd /tmp/wescamp-build-sys-templates/po

verbose_message "Cleansing temporary directories of '.svn' directories..."
echo ""
rm -rf ./.svn

# Move templates to destination
cp -rf /tmp/wescamp-build-sys-templates/. $OUTPUT_DIRECTORY/

# Enter output directory
echo "Entering $OUTPUT_DIRECTORY..."
echo ""
cd $OUTPUT_DIRECTORY

# Clean up temporary directories
verbose_message "Smiting temporary directories..."
echo ""
rm -rf /tmp/wescamp-build-sys-templates


check_for_file "po/LINGUAS"
echo "Creating 'LINGUAS' in $OUTPUT_DIRECTORY/po..."
echo $LINGUAS > $OUTPUT_DIRECTORY/po/LINGUAS

# Replace placeholders with the value of ADDON_DIRECTORY_NAME
echo ""
echo "Replacing placeholder value 'foobar' with '$ADDON_DIRECTORY_NAME' using 'sed' in..."
echo "... '$OUTPUT_DIRECTORY/campaign.def'..."
sed -i s/foobar/$ADDON_DIRECTORY_NAME/g $OUTPUT_DIRECTORY/campaign.def
echo "... '$OUTPUT_DIRECTORY/po/Makefile'..."
sed -i s/foobar/$ADDON_DIRECTORY_NAME/g $OUTPUT_DIRECTORY/po/Makefile

# Enter the output directory
echo ""
echo "Entering '$OUTPUT_DIRECTORY'..."
cd $OUTPUT_DIRECTORY

# Generate pot file
echo ""
echo "Generating the pot file..."
verbose_message "... with 'make'..."
make

# Enter input directory
echo ""
echo "Entering '$INPUT_DIRECTORY'..."
cd $INPUT_DIRECTORY

# Merge stuff from the target addon with the pot using wmlxgettext
echo ""
echo "Merging strings from the target addon with the pot using wmlxgettext..."
wmlxgettext --domain=wesnoth-$ADDON_DIRECTORY_NAME --directory=. `sh $OUTPUT_DIRECTORY/po/FINDCFG` > $OUTPUT_DIRECTORY/po/wesnoth-$ADDON_DIRECTORY_NAME.pot

# Enter 'po'
echo ""
echo "Entering '$OUTPUT_DIRECTORY/po'..."
cd $OUTPUT_DIRECTORY/po

# Generate po files
echo ""
echo "Generating po files..."
verbose_message "... with 'for i in `cat $OUTPUT_DIRECTORY/po/LINGUAS`; do msginit -l $i --no-translator --input $OUTPUT_DIRECTORY/po/wesnoth-$ADDON_DIRECTORY_NAME.pot; done'..."
for i in `cat $OUTPUT_DIRECTORY/po/LINGUAS`; do msginit -l $i --no-translator --input $OUTPUT_DIRECTORY/po/wesnoth-$ADDON_DIRECTORY_NAME.pot; done

# Hack to ensure that fur_IT.po and nb_NO.po are made
echo ""
echo "Renaming fur.po and nb.po..."
mv $OUTPUT_DIRECTORY/po/fur.po fur_IT.po
mv $OUTPUT_DIRECTORY/po/nb.po nb_NO.po
sed -i 's/fur/fur_IT/g' $OUTPUT_DIRECTORY/po/fur_IT.po
sed -i 's/nb/nb_NO/g' $OUTPUT_DIRECTORY/po/nb_NO.po

# Kill cruft
echo ""
echo "Killing cruft..."
rm $OUTPUT_DIRECTORY/config.status
rm $OUTPUT_DIRECTORY/po/*gmo

# Done!
echo ""
echo "Done."

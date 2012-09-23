#! /bin/bash
#
# Requires: Bash, gettext, and wmlxgettext (the Perl version)
#
# lbundle.py:
# http://websvn.kde.org/*checkout*/trunk/l10n-support/scripts/lbundle-check.py
#
# wmlxgettext (Perl):
# http://svn.gna.org/viewcvs/*checkout*/wesnoth/trunk/utils/wmlxgettext
#
#  Copyright © 2010–2012 by Steven Panek <Majora700@gmail.com>
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
		Usage: init-build-sys.sh [options] [version_switch] ADDON_DIRECTORY OUTPUT_DIRECTORY

		init-build-sys.sh generates the translation build system for addons as well as po files.

		ADDON_DIRECTORY represents the name of the directory that contains the targeted addon, while OUTPUT_DIRECTORY represents the directory where the "po" directory and a few other files belonging to the build system will be dumped.

		Options:

		--help          | -h       Displays this information and exits.
		--verbose       | -v       Enables extra information.

		Supported versions:

		--1.0
		--1.2
		--1.4
		--1.6
		--1.8
		--1.10
		--trunk

		Please note that 'support' for 1.0 and 1.2 is merely there for fun, thus we do not know if it truly works; if you find that what this script generates for 1.0/1.2 does not work, do not get mad.

		This script should be run in the directory that contains the target addon's directory.

		Report any issues to Espreon.


		NOTES FOR ACTUAL USAGE:
		-run the script *from the addon translation repo's root*, that is Invasion_from_the_Unknown-1.10 or the like
		-invoke it as path/to/init-build-sys.sh --1.10 Invasion_from_the_Unknown .
		-DO NOT FORGET THE PERIOD, or it might decide to write to your home directory instead
	EOD
	exit
fi

# Macros/whatevers that check for textdomain_check and textdomain_check_trunk
# Syntax: (name) () (url string)
need_thingy()
{
    echo "$1 was not found in your PATH; please put it in your PATH.

If you do not have $1, you can get it from here: $2" >&2
    echo "Aborting..." >&2
    exit 7
}

check_for_thingy()
{
    type -P $1 &>/dev/null || need_thingy $1 $2
}

need_perl_wmlxgettext()
{
    echo "The Perl version of wmlxgettext was not found in your PATH; please put it in your PATH.

If you do not have it, you can get it from here: http://svn.gna.org/viewcvs/*checkout*/wesnoth/trunk/utils/wmlxgettext" >&2
    echo "Aborting..." >&2
    exit 7
}

# Yes, I know that this is a bit hacky, but... yeahz...
check_for_perl_wmlxgettext()
{
    wmlxgettext | head -n 3 | grep "PACKAGE VERSION" > /dev/null || need_perl_wmlxgettext
}

message()
{
    if [ "${QUIET}" = "no" ]; then
        echo "$@"
    fi
}

verbose_message()
{
    if [ "${VERBOSE}" = "yes" ]; then
       echo "VERBOSE: $1"
    fi
}

check_for_perl_wmlxgettext
# check_for_thingy "lbundle-check.py" "http://websvn.kde.org/*checkout*/trunk/l10n-support/scripts/lbundle-check.py"

# Set some variables

# Find the location of this script and the directory that contains it
PATH_TO_ME=$(readlink -f $0)
MY_DIRECTORY="`dirname $PATH_TO_ME`"

# Disable verbosity by default
VERBOSE="no"

# Disable quietness by default
QUIET="no"

# Input/output
OUTPUT_DIRECTORY="null"
INPUT_DIRECTORY="null"

# Name of addon directory
ADDON_DIRECTORY_NAME="."

# Version on which the target addon runs
VERSION="null"

# Parse parameters
while [ "${1}" != "" ] || [ "${1}" = "--help" ] || [ "${1}" = "-h" ]; do

    # Determine whether or not to enable more information
    if [ "${1}" = "--verbose" ] || [ "${1}" = "-v" ]; then
        VERBOSE="yes"
        shift

    elif [ "${1}" = "--quiet" ] || [ "${1}" = "-q" ]; then
        VERBOSE="no"
        QUIET="yes"
        shift

    # Set version that the target addon uses
    # Yes, I am such a noob
    elif [ "${1}" = "--trunk" ]; then
        VERSION="trunk"
        shift

    elif [ "${1}" = "--1.10" ]; then
        VERSION="1.10"
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
message ""
message "Creating the build system in $OUTPUT_DIRECTORY..."

# Move templates to destination
cp -rf $MY_DIRECTORY/templates/* $OUTPUT_DIRECTORY/

# Enter output directory
message "Entering $OUTPUT_DIRECTORY..."
message ""
cd $OUTPUT_DIRECTORY

message "Creating 'LINGUAS' in $OUTPUT_DIRECTORY/po..."
echo $LINGUAS > $OUTPUT_DIRECTORY/po/LINGUAS

# Replace placeholders with the value of ADDON_DIRECTORY_NAME
message ""
message "Replacing placeholder value 'foobar' with '$ADDON_DIRECTORY_NAME' using 'sed' in..."
message "... '$OUTPUT_DIRECTORY/campaign.def'..."
sed -i s/foobar/$ADDON_DIRECTORY_NAME/g $OUTPUT_DIRECTORY/campaign.def
message ""
message "Replacing placeholder value 'branch-number' with '$VERSION' using 'sed' in ..."
message "... '$OUTPUT_DIRECTORY/campaign.def'..."
sed -i s/branch-number/$VERSION/g $OUTPUT_DIRECTORY/campaign.def

# Enter the output directory
message ""
message "Entering '$OUTPUT_DIRECTORY'..."
cd $OUTPUT_DIRECTORY

# Create the pot file
if test ! -f $OUTPUT_DIRECTORY/po/wesnoth-$ADDON_DIRECTORY_NAME.pot; then
    message ""
    message "Generating the pot using wmlxgettext..."
    if ! wmlxgettext --domain=wesnoth-$ADDON_DIRECTORY_NAME --directory=. `sh $OUTPUT_DIRECTORY/po/FINDCFG` > $OUTPUT_DIRECTORY/po/wesnoth-$ADDON_DIRECTORY_NAME.pot; then
        echo 'wmlxgettext failed!' >&2
        exit 6
    fi

    verbose_message "Filling in the Project-Id-Version field..."
    sed -i "s/PACKAGE VERSION/$ADDON_DIRECTORY_NAME-$VERSION/g" $OUTPUT_DIRECTORY/po/wesnoth-$ADDON_DIRECTORY_NAME.pot

    verbose_message "Clearing the Report-Msgid-Bugs-To field..."
    # Clear the Report-Msgid-Bugs-To field
    sed -i 's/Report-Msgid-Bugs-To: http:\/\/bugs.wesnoth.org\//Report-Msgid-Bugs-To: /g' $OUTPUT_DIRECTORY/po/wesnoth-$ADDON_DIRECTORY_NAME.pot
fi

# Enter 'po'
message ""
message "Entering '$OUTPUT_DIRECTORY/po'..."
cd $OUTPUT_DIRECTORY/po

# Generate po files
message ""
message -n "Generating po files..."
for i in `cat $OUTPUT_DIRECTORY/po/LINGUAS`; do
    if test ! -f $OUTPUT_DIRECTORY/po/$i.po; then
        message -n " $i.po"
        if test "x$i" = "xen_GB" -o "x$i" = "xen@shaw"; then
            # Hack to generate en_GB.po and en@shaw.po files without automatic translations
            # Use de, for it has similar plurals info
            msginit -l de --no-translator --input $OUTPUT_DIRECTORY/po/wesnoth-$ADDON_DIRECTORY_NAME.pot --output $i.po 2>&1|grep -vE '^Created' >&2 && exit 8;
        elif test $i = "fur_IT" -o $i = "nb_NO"; then
            # Gettext refuses to use the suffix, so override it
            msginit -l $i --no-translator --input $OUTPUT_DIRECTORY/po/wesnoth-$ADDON_DIRECTORY_NAME.pot --output $i.po 2>&1|grep -vE '^Created' >&2 && exit 8;
        else
            msginit -l $i --no-translator --input $OUTPUT_DIRECTORY/po/wesnoth-$ADDON_DIRECTORY_NAME.pot 2>&1|grep -vE '^Created' >&2 && exit 8;
        fi
    fi
done
message

# Hack to ensure that the hacked po files contain the right language
message ""
if test -f $OUTPUT_DIRECTORY/po/en_GB.po && ! grep "Language: en_GB" $OUTPUT_DIRECTORY/po/en_GB.po >/dev/null; then
    message "Fixing language of en_GB.po"
    sed -i 's/\"Language: de\\n\"/\"Language: en_GB\\n\"/g' $OUTPUT_DIRECTORY/po/en_GB.po
fi
if test -f $OUTPUT_DIRECTORY/po/en@shaw.po && ! grep "Language: en@shaw" $OUTPUT_DIRECTORY/po/en@shaw.po >/dev/null; then
    message "Fixing language of en@shaw.po"
    sed -i 's/\"Language: de\\n\"/\"Language: en@shaw\\n\"/g' $OUTPUT_DIRECTORY/po/en@shaw.po
fi
if test -f $OUTPUT_DIRECTORY/po/fur_IT.po && ! grep "Language: fur_IT" $OUTPUT_DIRECTORY/po/fur_IT.po >/dev/null; then
    message "Fixing language of fur_IT.po"
    sed -i 's/\"Language: fur\\n\"/\"Language: fur_IT\\n\"/g' $OUTPUT_DIRECTORY/po/fur_IT.po
fi
if test -f $OUTPUT_DIRECTORY/po/nb_NO.po && ! grep "Language: nb_NO" $OUTPUT_DIRECTORY/po/nb_NO.po >/dev/null; then
    message "Fixing language of nb_NO.po"
    sed -i 's/\"Language: nb\\n\"/\"Language: nb_NO\\n\"/g' $OUTPUT_DIRECTORY/po/nb_NO.po
fi
# Hacks to fix the plural forms
if test -f $OUTPUT_DIRECTORY/po/ga.po && ! grep "Plural-Forms: nplurals=5" $OUTPUT_DIRECTORY/po/ga.po >/dev/null; then
    message "Fixing plurals info for Irish"
    sed -i 's/\"Plural-Forms: nplurals=3; plural=n==1 ? 0 : n==2 ? 1 : 2;\\n\"/"Plural-Forms: nplurals=5; plural=n==1 ? 0 : n==2 ? 1 : n<7 ? 2 : n<11 ? 3 : 4;\\n"/g' $OUTPUT_DIRECTORY/po/ga.po
fi
if test -f $OUTPUT_DIRECTORY/po/ang.po && ! grep "Plural-Forms: nplurals=3" $OUTPUT_DIRECTORY/po/ang.po >/dev/null; then
    message "Adding plurals info for Old English (futhorc)"
    sed -i 's/\(Language: ang.*\\n"\)/&\n"Plural-Forms: nplurals=3; plural=n==1 ? 0 : n==2 ? 1 : 2;\\n"/' $OUTPUT_DIRECTORY/po/ang.po
fi
if test -f $OUTPUT_DIRECTORY/po/ang@latin.po && ! grep "Plural-Forms: nplurals=3" $OUTPUT_DIRECTORY/po/ang@latin.po >/dev/null; then
    message "Adding plurals info for Old English (latin)"
    sed -i 's/\(Language: ang@latin.*\\n"\)/&\n"Plural-Forms: nplurals=3; plural=n==1 ? 0 : n==2 ? 1 : 2;\\n"/' $OUTPUT_DIRECTORY/po/ang@latin.po
fi

# Done!
message ""
message "Done."

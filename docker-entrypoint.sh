#!/bin/bash

# license instalation
# need to copy the file first because the install process remove
# the original license file
#
# there is also an option to pass license via environment variable (base64)
# MULE_LICENSE="$( base64 license.lic )"
if [ -r "/license.lic" ]; then
	echo "ENTRYPOINT: Installing Mule License (volume /license.lic)"
	cp /license.lic /tmp/license.lic
	$MULE_HOME/bin/mule -installLicense /tmp/license.lic
elif [ -n "$MULE_LICENSE" ]; then
	echo "ENTRYPOINT: Installing Mule License (environment variable MULE_LICENSE)"
	echo "$MULE_LICENSE" | base64 -d > /tmp/license.lic
	$MULE_HOME/bin/mule -installLicense /tmp/license.lic
else
	echo "ENTRYPOINT: License not installed, no license provided"
	[ "$MULE_EVALUATION" == TRUE ] || exit 1
fi

if $MULE_HOME/bin/mule -verifyLicense | grep -q "Evaluation = true"; then
	echo "ENTRYPOINT: License not installed, license invalid"
	[ "$MULE_EVALUATION" == TRUE ] || exit 1
fi

$MULE_HOME/bin/mule

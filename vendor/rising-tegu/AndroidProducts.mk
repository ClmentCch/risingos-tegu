#
# SPDX-License-Identifier: Apache-2.0
#
# RisingOS 9 tegu — product discovery.
#
# This directory is checked out at vendor/rising-tegu in the Android tree. build/make
# scans vendor/*/*/AndroidProducts.mk, so `rising_tegu` becomes a lunch target without
# touching the upstream LineageOS device tree.
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/rising_tegu.mk

COMMON_LUNCH_CHOICES := \
    rising_tegu-userdebug \
    rising_tegu-user \
    rising_tegu-eng

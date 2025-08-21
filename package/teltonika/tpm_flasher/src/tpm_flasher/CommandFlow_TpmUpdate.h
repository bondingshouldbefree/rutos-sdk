﻿/**
 *  @brief      Declares the command flow to update the TPM firmware.
 *  @details    This module processes the firmware update. Afterwards the result is returned to the calling module.
 *  @file       CommandFlow_TpmUpdate.h
 *
 *  Copyright 2014 - 2024 Infineon Technologies AG ( www.infineon.com )
 *
 *  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *  1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#pragma once

#include "StdInclude.h"
#include "TPMFactoryUpdStruct.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 *  @brief      Processes a sequence of TPM update related commands to update the firmware.
 *  @details    This module processes the firmware update. Afterwards the result is returned to the calling module.
 *              The function utilizes the MicroTSS library.
 *
 *  @param      PpTpmUpdate         Pointer to an initialized IfxUpdate structure to be filled in.
 *
 *  @retval     RC_SUCCESS          The operation completed successfully.
 *  @retval     RC_E_BAD_PARAMETER  An invalid parameter was passed to the function. PpTpmUpdate is NULL or invalid.
 *  @retval     RC_E_FAIL           An unexpected error occurred.
 *  @retval     ...                 Error codes from called functions.
 */
_Check_return_
unsigned int
CommandFlow_TpmUpdate_UpdateFirmware(
    _Inout_ IfxUpdate* PpTpmUpdate);

/**
 *  @brief      Prepare a firmware update.
 *  @details    This function will prepare the TPM to do a firmware update.
 *
 *  @param      PpTpmUpdate         Pointer to an initialized IfxUpdate structure to be filled in.
 *
 *  @retval     RC_SUCCESS          The operation completed successfully.
 *  @retval     RC_E_BAD_PARAMETER  An invalid parameter was passed to the function.
 *  @retval     RC_E_FAIL           An unexpected error occurred.
 *  @retval     ...                 Error codes from called functions.
 */
_Check_return_
unsigned int
CommandFlow_TpmUpdate_PrepareFirmwareUpdate(
    _Inout_ IfxUpdate* PpTpmUpdate);

/**
 *  @brief      Check if a firmware update is possible.
 *  @details    This function will check if the firmware is updatable with the given firmware image
 *
 *  @param      PpTpmUpdate             Pointer to an initialized IfxUpdate structure to be filled in.
 *
 *  @retval     RC_SUCCESS              The operation completed successfully.
 *  @retval     RC_E_BAD_PARAMETER      An invalid parameter was passed to the function.
 *  @retval     RC_E_INVALID_FW_OPTION  In case of an invalid firmware option argument.
 *  @retval     RC_E_FAIL               An unexpected error occurred.
 *  @retval     ...                     Error codes from Micro TSS functions.
 */
_Check_return_
unsigned int
CommandFlow_TpmUpdate_IsFirmwareUpdatable(
    _Inout_ IfxUpdate* PpTpmUpdate);

/**
 *  @brief      Take TPM Ownership with hard coded hash value.
 *  @details    The corresponding TPM Owner authentication is described in the user manual.
 *
 *  @retval     RC_SUCCESS                      TPM Ownership was taken successfully.
 *  @retval     RC_E_FAIL                       An unexpected error occurred.
 *  @retval     RC_E_TPM12_DISABLED_DEACTIVATED In case the TPM is disabled and deactivated.
 *  @retval     ...                             Error codes from Micro TSS functions.
 */
_Check_return_
unsigned int
CommandFlow_TpmUpdate_PrepareTPM12Ownership();

/**
 *  @brief      Verify TPM1.2 owner authorization.
 *  @details    Verify TPM1.2 owner authorization.
 *
 *  @param      PtpmState                       The current TPM state.
 *  @retval     RC_SUCCESS                      TPM owner authorization was verified successfully.
 *  @retval     RC_E_FAIL                       An unexpected error occurred.
 *  @retval     RC_E_INVALID_OWNERAUTH_OPTION   Either an invalid file path was given in --ownerauth parameter or file was not 20 bytes in size.
 *  @retval     RC_E_TPM12_DISABLED_DEACTIVATED In case the TPM is disabled and deactivated.
 *  @retval     RC_E_TPM12_INVALID_OWNERAUTH    The owner authorization is invalid.
 *  @retval     ...                             Error codes from Micro TSS functions.
 */
_Check_return_
unsigned int
CommandFlow_TpmUpdate_VerifyTPM12Ownerauth(
    _In_ TPM_STATE PtpmState);

/**
 *  @brief      Parse the update configuration settings file
 *  @details
 *
 *  @param      PpTpmUpdate                         Contains information about the current TPM and can be filled up with information for the
 *                                                  corresponding Current return code which can be overwritten here.
 *  @retval     PunReturnValue                      In case PunReturnValue is not equal to RC_SUCCESS.
 *  @retval     RC_SUCCESS                          The operation completed successfully.
 *  @retval     RC_E_FAIL                           An unexpected error occurred.
 *  @retval     RC_E_INVALID_CONFIG_OPTION          A configuration file was given that cannot be opened.
 *  @retval     RC_E_FIRMWARE_UPDATE_NOT_FOUND      A firmware update for the current TPM version cannot be found.
 */
_Check_return_
unsigned int
CommandFlow_TpmUpdate_ProceedUpdateConfig(
    _Inout_ IfxUpdate* PpTpmUpdate);

/**
 *  @brief      Prepares a policy session for TPM firmware.
 *  @details    The function prepares a policy session for TPM Firmware Update and returns the session handle
 *              for non empty platform authorization using default policy behaviour utilizing policy command code or
 *              having options in authorization including the TPM Firmware Update command.
 *              Further the function returns the policy handle for an external created policy session.
 *
 *  @param      PphPolicySession                    Pointer to session handle that will be filled in by this method.
 *
 *  @retval     RC_SUCCESS                          The operation completed successfully.
 *  @retval     RC_E_BAD_PARAMETER                  An invalid parameter was passed to the function. It is invalid or NULL.
 *  @retval     RC_E_FAIL                           An unexpected error occurred.
 *  @retval     RC_E_PLATFORM_AUTH_NOT_EMPTY        In case PlatformAuth is not the Empty Buffer.
 *  @retval     RC_E_PLATFORM_HIERARCHY_DISABLED    In case platform hierarchy has been disabled.
 *  @retval     TPM_RC_VALUE                        In case policy command code has not been set correctly before calling TSS_TPM2_PolicyOR.
 *  @retval     ...                                 Error codes from called functions. like TPM error codes.
 */
_Check_return_
unsigned int
CommandFlow_TpmUpdate_GetTPM20PolicyHandle(
    _Out_ TSS_TPMI_SH_AUTH_SESSION* PphPolicySession);

/**
 *  @brief      Parses the update policy configuration settings
 *  @details    Parses the update policy configuration settings for a settings file based update flow
 *
 *  @param      PpPolicyDigestList      Pointer to an initialized buffer containing the concatonated policy digests.
 *
 *  @retval     RC_SUCCESS              The operation completed successfully.
 *  @retval     RC_E_BAD_PARAMETER      An invalid parameter was passed to the function. It is NULL or empty.
 *  @retval     RC_E_FAIL               An unexpected error occurred.
 */
_Check_return_
unsigned int
CommandFlow_TpmUpdate_ProceedUpdatePolicyConfig(
    _Out_ TSS_TPML_DIGEST* PpPolicyDigestList);

#ifdef __cplusplus
}
#endif

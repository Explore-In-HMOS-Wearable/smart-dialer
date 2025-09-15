import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { voipCall } from '@kit.CallServiceKit';
import { image } from '@kit.ImageKit';
import CallDataManager from '../model/CallDataManager';
import { BusinessError } from '@kit.BasicServicesKit';
import { common, Want } from '@kit.AbilityKit';
import DefaultCallData from '../model/TypeUtils';
import { observer } from '@kit.TelephonyKit';


@Entry
@Component
struct ContactDetail {
  contactId: number = 0
  name: string = ''
  phone: string = ''
  isLocal: boolean | null = null
  bundleName: string = '';
  callId: string = '';
  callIdPrefix: string = '';
  callIdIndex: number = 1;

  aboutToAppear() {
    const p = router.getParams() as Record<string, Object> | undefined
    if (p) {
      this.contactId = Number(p['id'] ?? 0)
      this.name = String(p['name'] ?? '')
      this.phone = String(p['phone'] ?? '')
      const raw = p['isLocal']
      this.isLocal = (raw === null || raw === undefined) ? null : Boolean(raw)
    }

    this.observeEvent();
    this.observeCallState();

  }

  observeEvent() {
    try {
      voipCall.on('voipCallUiEvent', (voipCallUiEventInfo) => {
        hilog.info(0x0000, 'SampleCode', 'voipCallUiEvent: ' + voipCallUiEventInfo);
        if (voipCallUiEventInfo?.voipCallUiEvent == voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_VOICE_ANSWER) {
          hilog.info(0x0000, '20240830', 'ready to report state: %{public}s', 'answered');
          voipCall.reportCallStateChange(voipCallUiEventInfo.callId, voipCall.VoipCallState.VOIP_CALL_STATE_ANSWERED);

          setTimeout(() => {
            hilog.info(0x0000, 'Index', 'answer success, state change to active');
            if (voipCallUiEventInfo.callId === AppStorage.get('voipCallId')) {
              AppStorage.setOrCreate('voipCallState', voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE);
            }
            AppStorage.setOrCreate('voipCallMuteState', false);
            let result = voipCall.reportCallStateChange(voipCallUiEventInfo.callId,
              voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE,
              voipCall.VoipCallType.VOIP_CALL_VOICE);
            result.then(() => {
              hilog.info(0x0000, 'Index', 'reportCallStateChange to active success');
            }).catch((error: BusinessError) => {
              hilog.error(0x0000, 'Index', 'reportCallStateChange to active error code:', error.code);
            });
            CallDataManager.getInstance()
              .updateCallStateById(voipCallUiEventInfo.callId, voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE);
          }, 3000);
        } else if (voipCallUiEventInfo?.voipCallUiEvent == voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_VIDEO_ANSWER) {
          voipCall.reportCallStateChange(voipCallUiEventInfo.callId, voipCall.VoipCallState.VOIP_CALL_STATE_ANSWERED);
          setTimeout(() => {
            hilog.info(0x0000, 'SampleCode', 'video answer success, state change to active');
            if (voipCallUiEventInfo.callId === AppStorage.get('voipCallId')) {
              AppStorage.setOrCreate('voipCallState', voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE);
            }
            AppStorage.setOrCreate('voipCallMuteState', false);
            let result = voipCall.reportCallStateChange(voipCallUiEventInfo.callId,
              voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE,
              voipCall.VoipCallType.VOIP_CALL_VIDEO);
            result.then(() => {
              hilog.info(0x0000, 'SampleCode', 'reportCallStateChange to active success');
            }).catch((error: BusinessError) => {
              hilog.error(0x0000, 'SampleCode', 'reportCallStateChange to active error code: ' + error.code);
            });
            CallDataManager.getInstance()
              .updateCallStateById(voipCallUiEventInfo.callId, voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE);
          }, 3000);
        } else if (voipCallUiEventInfo?.voipCallUiEvent == voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_REJECT) {
          setTimeout(() => {
            hilog.info(0x0000, 'SampleCode', 'reject success, state change to disconnected');
            if (voipCallUiEventInfo.callId === AppStorage.get('voipCallId')) {
              AppStorage.setOrCreate('voipCallState',
                voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED);
            }
            let result =
              voipCall.reportCallStateChange(voipCallUiEventInfo.callId,
                voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED);
            result.then(() => {
              hilog.info(0x0000, 'SampleCode', 'reportCallStateChange to disconnected success');
            }).catch((error: BusinessError) => {
              hilog.error(0x0000, 'SampleCode', 'reportCallStateChange to disconnected error code: ' + error.code);
            });
            CallDataManager.getInstance().removeCallById(voipCallUiEventInfo.callId);
          }, 100);
        } else if (voipCallUiEventInfo?.voipCallUiEvent == voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_HANGUP) {
          setTimeout(() => {
            hilog.info(0x0000, 'SampleCode', 'hangup success, state change to disconnected');
            if (voipCallUiEventInfo.callId === AppStorage.get('voipCallId')) {
              AppStorage.setOrCreate('voipCallState', voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED);
            }
            let result =
              voipCall.reportCallStateChange(voipCallUiEventInfo.callId,
                voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED);
            result.then(() => {
              hilog.info(0x0000, 'SampleCode', 'reportCallStateChange to disconnected success');
            }).catch((error: BusinessError) => {
              hilog.error(0x0000, 'SampleCode', 'reportCallStateChange to disconnected error code: ' + error.code);
            });
            CallDataManager.getInstance().removeCallById(voipCallUiEventInfo.callId);
          }, 100);
        } else if (voipCallUiEventInfo?.voipCallUiEvent ==
        voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_MUTED) {
          hilog.info(0x0000, 'SampleCode', 'receive voip call event muted');
          let result = voipCall.reportCallAudioEventChange(voipCallUiEventInfo.callId,
            voipCall.CallAudioEvent.AUDIO_EVENT_MUTED);
          result.then(() => {
            hilog.info(0x0000, 'SampleCode', 'reportCallAudioEventChange mute event success');
          }).catch((error: BusinessError) => {
            hilog.error(0x0000, 'SampleCode', 'reportCallAudioEventChange mute event error code: ' + error.code);
          });
          AppStorage.setOrCreate('voipCallMuteState', true);
        } else if (voipCallUiEventInfo?.voipCallUiEvent ==
        voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_UNMUTED) {
          hilog.info(0x0000, 'SampleCode', 'receive voip call event unmuted');
          let result = voipCall.reportCallAudioEventChange(voipCallUiEventInfo.callId,
            voipCall.CallAudioEvent.AUDIO_EVENT_UNMUTED);
          result.then(() => {
            hilog.info(0x0000, 'SampleCode', 'reportCallAudioEventChange unmute event success');
          }).catch((error: BusinessError) => {
            hilog.error(0x0000, 'SampleCode', 'reportCallAudioEventChange unmute event error code: ' + error.code);
          });
          AppStorage.setOrCreate('voipCallMuteState', false);
        } else if (voipCallUiEventInfo?.voipCallUiEvent == voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_SPEAKER_ON) {
          hilog.info(0x0000, 'SampleCode', 'receive voip call event speaker on');
        } else if (voipCallUiEventInfo?.voipCallUiEvent == voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_SPEAKER_OFF) {
          hilog.info(0x0000, 'SampleCode', 'receive voip call event speaker off');
        }
      });
    } catch (err) {
      hilog.error(0x0000, 'SampleCode', 'voipCallUiEvent on error: ' + err);
    }
  }
  observeCallState() {
    observer.on('callStateChange', (data) => {
      hilog.info(0x0000, 'SampleCode', 'callStateChange: ' + JSON.stringify(data));
    })
  }

  build() {
    Column({ space: 12 }) {

      Text(`Name: ${this.name}`)
      Text(`Phone: ${this.phone}`)

      Button('Outgoing Call')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 10 })
        .onClick(() => {
          hilog.info(0x0000, 'SampleCode', 'reportOutgoingCall');
          this.callId = this.callIdPrefix + (this.callIdIndex++) + '';
          let voipCallAttribute: voipCall.VoipCallAttribute = {
            callId: this.callId,
            voipCallType: voipCall.VoipCallType.VOIP_CALL_VOICE,
            userName: 'Jack',
            userProfile: image.createPixelMapSync(new ArrayBuffer(100), { size: { width: 90, height: 90 } }),
            abilityName: 'VoipCallAbility',
            voipCallState: voipCall.VoipCallState.VOIP_CALL_STATE_DIALING
          };
          let result = voipCall.reportOutgoingCall(voipCallAttribute);
          result.then((errorReason: voipCall.ErrorReason) => {
            hilog.info(0x0000, 'SampleCode', 'reportOutgoingCall errorReason: ' + errorReason);
            if (errorReason == voipCall.ErrorReason.ERROR_NONE) {
              CallDataManager.getInstance()
                .addCall({
                  callId: voipCallAttribute.callId,
                  callState: voipCallAttribute.voipCallState,
                  callType: voipCallAttribute.voipCallType
                });
              AppStorage.setOrCreate('voipCallId', this.callId);
              AppStorage.setOrCreate('voipCallType', voipCall.VoipCallType.VOIP_CALL_VOICE);
              AppStorage.setOrCreate('voipCallState', voipCall.VoipCallState.VOIP_CALL_STATE_DIALING);
              AppStorage.setOrCreate('voipCallMuteState', false);
              // Directly show the dialer screen for an outgoing call.
              let want: Want = {
                bundleName: this.bundleName,
                abilityName: 'VoipCallAbility'
              };
              AppStorage.get<common.UIAbilityContext>('AbilityContext')?.startAbility(want);

              this.handleDialingCallTimeout(this.callId);
            }
          }).catch((error: BusinessError) => {
            hilog.error(0x0000, 'SampleCode', 'reportOutgoingCall error code: ' + error.code);
          });
        })


      Button('Back')
        .onClick(() => router.back())
        .type(ButtonType.Capsule)
    }
    .padding(16)
    .width('100%')
  }

  handleDialingCallTimeout(callId: string) {
    // Automatic timeout after 60s.
    setTimeout((callId: string) => {
      let callData: DefaultCallData | undefined = CallDataManager.getInstance().getCallById(callId);
      hilog.info(0x0000, 'SampleCode', 'handleDialingCallTimeout callId: ' + callId + ', callData: ' + callData);
      if (!callData || callData.callState !== voipCall.VoipCallState.VOIP_CALL_STATE_DIALING) {
        return;
      }
      hilog.info(0x0000, 'SampleCode', 'video dial timeout, state change to disconnected');
      AppStorage.setOrCreate('voipCallState', voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED);
      let result = voipCall.reportCallStateChange(callId, voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED);
      result.then(() => {
        hilog.info(0x0000, 'SampleCode', 'reportCallStateChange to disconnected success');
      }).catch((error: BusinessError) => {
        hilog.error(0x0000, 'SampleCode', 'reportCallStateChange to disconnected error: ' + error.code);
      });
      CallDataManager.getInstance().removeCallById(callId);
    }, 60000, callId);
  }

}

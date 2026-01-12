import { common, abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { contact } from '@kit.ContactsKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ArcList, ArcListItem, ArcListAttribute, ArcListItemAttribute } from '@kit.ArkUI';

import {
  LengthMetrics,
  LengthUnit,
  ArcButton,
  ArcButtonOptions,
  ArcButtonStatus,
  ArcButtonStyleMode,
  ArcButtonPosition,
  display
} from '@kit.ArkUI';

interface AddedContactRow {
  id: number;
  name: string;
  phone: string;
  isLocal: boolean | null;
}
export interface ContactDetailParam {
  id: number;
  name: string;
  phone: string;
  isLocal: boolean | null;
}


interface ContactWithOptionalIdKey {
  id?: number;
  key?: string;
}

interface AddContactResult {
  id: number;
  key?: string;
}

@CustomDialog
struct AddContactDialog {
  controller?: CustomDialogController
  name: string = ''
  phone: string = ''
  onConfirm: (name: string, phone: string) => void = () => {
  }

  private close() {
    this.controller?.close()
  }

  build() {
    Column({ space: 12 }) {
      Text('Add Contact')
        .fontSize(20)

      TextArea({ text: this.name, placeholder: 'Name' })
        .onChange((val: string) => this.name = val)

      TextArea({ text: this.phone, placeholder: 'Phone' })
        .onChange((val: string) => this.phone = val)

      Button('Confirm')
        .onClick(() => {
          this.onConfirm(this.name.trim(), this.phone.trim())
          this.close()
        })
        .type(ButtonType.Capsule)
    }
    .backgroundColor(Color.Black)
    .padding(16)
  }
}


@Entry
@Component
struct Index {
  pageInfos: NavPathStack = new NavPathStack(); // <<< EKLENDİ
  topOptions: ArcButtonOptions = new ArcButtonOptions({});
  @State isLoading: boolean = false;
  scroller: Scroller = new Scroller()
  screenW: number = 360;
  screenH: number = 360;
  dialogController: CustomDialogController | null = null

  aboutToAppear(): void {

    try {
      const d = display.getDefaultDisplaySync();
      this.screenW = d.width;
      this.screenH = d.height;
    } catch (e) {
      console.warn('display.getDefaultDisplaySync failed, using defaults.');
    }


    this.topOptions = new ArcButtonOptions({
      label: 'Add',
      status: ArcButtonStatus.NORMAL,
      position: ArcButtonPosition.TOP_EDGE,
      styleMode: ArcButtonStyleMode.EMPHASIZED_LIGHT,
      fontSize: new LengthMetrics(15, LengthUnit.FP),
      shadowEnabled: true,
      onClick: () => {
        this.alertDialogShow();
      }
    })

    this.dialogController = new CustomDialogController({
      builder: AddContactDialog({
        onConfirm: (name: string, phone: string): void => this.addContactByPermissionsWith(name, phone)
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: true,
      width: this.screenW,
      height: this.screenH,
      cornerRadius: 0,
      backgroundColor: Color.Transparent,
      shadow: {
        radius: 0,
        color: Color.Transparent,
        offsetX: 0,
        offsetY: 0
      }
    });

    this.listContact();
  }

  private addContactByPermissionsWith(name: string, phone: string) {
    const ctx = this.hostCtx();
    const permissions: Array<Permissions> = ['ohos.permission.WRITE_CONTACTS'];
    const info: contact.Contact = {
      name: { fullName: name || 'Unnamed' },
      phoneNumbers: [{ phoneNumber: phone || '' }]
    };

    abilityAccessCtrl.createAtManager().requestPermissionsFromUser(ctx, permissions).then(() => {
      try {
        contact.addContact(ctx, info, (err: BusinessError, data: number) => {
          if (err) {
            console.error(`addContact error: ${err.code} - ${err.message}`);
            return;
          }
          const id: number = data;
          const row: AddedContactRow = {
            id,
            name: info.name?.fullName ?? '',
            phone: info.phoneNumbers?.[0]?.phoneNumber ?? '',
            isLocal: null
          };
          this.addedContacts = [row, ...this.addedContacts];
        });
      } catch (e) {
        const be = e as BusinessError;
        console.error(`addContact try/catch: ${be.code} - ${be.message}`);
      }
    });
  }

  private ui(): UIContext {
    const u = this.getUIContext();
    if (!u) {
      throw new Error('[Index] UIContext not available');
    }
    return u;
  }

  private hostCtx(): common.UIAbilityContext {
    return this.ui().getHostContext() as common.UIAbilityContext;
  }

  aboutToDisappear() {
    this.dialogController = null
  }

  alertDialogShow() {
    this.dialogController?.open()
  }

  @State addedContacts: Array<AddedContactRow> = [];

  private async requestPerms(perms: Array<Permissions>): Promise<void> {
    const ctx = this.hostCtx();
    await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(ctx, perms);
  }

  async wipeAllContacts() {
    const ctx = this.hostCtx();
    try {
      await this.requestPerms(['ohos.permission.READ_CONTACTS', 'ohos.permission.WRITE_CONTACTS']);

      const contacts: Array<contact.Contact> = await new Promise((resolve, reject) => {
        contact.queryContacts(ctx, (err: BusinessError, data: Array<contact.Contact>) => {
          if (err) {
            reject(err);
            return;
          }
          resolve(data);
        });
      });

      for (const c of contacts) {
        const t = c as ContactWithOptionalIdKey;
        const id: number = (typeof t.id === 'number' && t.id > 0) ? t.id : Number(t.key ?? 0);
        if (!id || Number.isNaN(id)) {
          continue;
        }

        try {
          await new Promise<void>((resolve, reject) => {
            contact.deleteContact(ctx, id.toString(), (err: BusinessError) => {
              if (err) {
                reject(err);
                return;
              }
              resolve();
            });
          });
        } catch (e) {
          const be = e as BusinessError;
          console.error(`deleteContact failed for id=${id}: ${be.code} - ${be.message}`);
        }
      }

      this.addedContacts = [];
      console.info('All contacts wiped for test.');
    } catch (e) {
      const be = e as BusinessError;
      console.error(`wipeAllContacts error: ${be.code} - ${be.message}`);
    }
  }

  addContactByPermissions() {
    const ctx = this.hostCtx();
    const permissions: Array<Permissions> = ['ohos.permission.WRITE_CONTACTS'];
    const info: contact.Contact = {
      name: { fullName: 'Jogn Doe' },
      phoneNumbers: [{ phoneNumber: '1234567890' }]
    };

    abilityAccessCtrl.createAtManager().requestPermissionsFromUser(ctx, permissions).then(() => {
      try {
        contact.addContact(ctx, info, (err: BusinessError, data: number) => {
          if (err) {
            console.error(`addContact error: ${err.code} - ${err.message}`);
            return;
          }
          const id: number = data;
          const name: string = info.name?.fullName ?? '';
          const phone: string = info.phoneNumbers?.[0]?.phoneNumber ?? '';
          const row: AddedContactRow = {
            id,
            name,
            phone,
            isLocal: null
          };
          this.addedContacts = [row, ...this.addedContacts];
        });
      } catch (e) {
        const be = e as BusinessError;
        console.error(`addContact try/catch: ${be.code} - ${be.message}`);
      }
    });
  }

  async listContact() {
    this.isLoading = true;
    const ctx = this.hostCtx();
    try {
      await this.requestPerms(['ohos.permission.READ_CONTACTS']);

      const contacts: Array<contact.Contact> = await new Promise((resolve, reject) => {
        contact.queryContacts(ctx, (err: BusinessError, data: Array<contact.Contact>) => {
          if (err) {
            reject(err);
            return;
          }
          resolve(data);
        });
      });

      const rows: Array<AddedContactRow> = [];
      for (const c of contacts) {
        const t: ContactWithOptionalIdKey = c as ContactWithOptionalIdKey;
        const id: number = (typeof t.id === 'number' && t.id > 0) ? t.id : Number(t.key ?? 0);

        const name: string = c.name?.fullName ?? '';
        const phone: string = c.phoneNumbers?.[0]?.phoneNumber ?? '';

        let isLocal: boolean | null = null;
        try {
          if (id > 0) {
            isLocal = await contact.isLocalContact(ctx, id);
          }
        } catch {
          isLocal = null;
        }

        rows.push({
          id: id > 0 ? id : 0,
          name,
          phone,
          isLocal
        });
      }

      rows.sort((a, b) => a.name.localeCompare(b.name));
      this.addedContacts = rows;
    } catch (e) {
      const be = e as BusinessError;
      console.error(`listContact error: ${be.code} - ${be.message}`);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Navigation(this.pageInfos) {


      Column() {
        ArcButton({ options: this.topOptions })

        if (this.isLoading) {
          Column() {
            LoadingProgress()
            Text('Loading contacts...')
              .fontSize(14)
              .fontColor('#666666')
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .height('100%')
        } else {

          ArcList({ initialIndex: 0 }) {
            ForEach(this.addedContacts, (row: AddedContactRow) => {
              ArcListItem() {
                Row() {
                  Column({ space: 4 }) {
                    Text(`${row.name} ${row.phone}`)
                      .fontWeight(FontWeight.Medium)
                      .fontSize(12)
                  }
                  .width('100%')
                  .padding(8)
                }
                .borderRadius(8)
                .borderWidth(1)
                .borderColor('#F5F5F7')
                .margin({ bottom: 8 })
                .onClick(() => this.openContact(row))
                .width('100%')
              }
              .align(Alignment.Center)
            }, (row: AddedContactRow) => `${row.id}`)
          }
          .width('100%')
          .height('100%')
          .focusable(true)
          .focusOnTouch(true)
        }
      }
      .height('100%')
      .width('100%')
    }.hideTitleBar(true)
    .hideBackButton(true)
  }



  private openContact(row: AddedContactRow) {
    const param: ContactDetailParam = {
      id: row.id,
      name: row.name,
      phone: row.phone,
      isLocal: row.isLocal
    };
    this.pageInfos.pushPathByName('ContactDetail', param);
  }

}

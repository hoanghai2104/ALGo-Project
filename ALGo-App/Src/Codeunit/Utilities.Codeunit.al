codeunit 50119 Utilities
{
    procedure SendNotification(Message: Text; Scope: NotificationScope; var Notification: Notification)
    begin
        DisposeNotification(Notification);
        Notification.Message := Message;
        Notification.Scope := Scope;
        Notification.Send();
    end;

    procedure DisposeNotification(var Notification: Notification)
    begin
        if not IsNullGuid(Notification.Id) then
            Notification.Recall();
    end;
}
namespace Marechal.DataverseMapping.CRM;
using Microsoft.Integration.DynamicsFieldService;
using Microsoft.Integration.SyncEngine;
using Microsoft.Service.Document;
codeunit 50118 "Service Order Integration Mgt."
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterTransferRecordFields', '', false, false)]
    local procedure WorkOrderOnAfterTransferRecordFields(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var AdditionalFieldsWereModified: Boolean; DestinationIsInserted: Boolean)
    var
        ServiceHeader: Record "Service Header";
        WorkOrder: Record "FS Work Order";
    begin
        /* 
         Switch to using the real field from Dataverse and field mappings in BC. (For faster synchronization).
         There is already a Power Automate flow that inserts a Dataverse Entity Changes record to notify BC when msdyn_workorder is CUD.
         On the FS side, add logic to set To Invoice = true when Status = Posted.
        */
        exit;

        if (SourceRecordRef.Number <> Database::"FS Work Order") or (DestinationRecordRef.Number <> Database::"Service Header") then
            exit;

        SourceRecordRef.SetTable(WorkOrder);
        DestinationRecordRef.SetTable(ServiceHeader);

        ServiceHeader."To Invoice" := WorkOrder.SystemStatus = WorkOrder.SystemStatus::Posted;
        DestinationRecordRef.GetTable(ServiceHeader);
    end;
}

page 50115 "ELCA Enqueue Job Sync. Api"
{
    Caption = 'Enqueue Job Sync';
    ApplicationArea = API;
    PageType = API;
    APIPublisher = 'ELCA';
    APIGroup = 'CRMIntegration';
    APIVersion = 'v2.0';
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    EntityName = 'enqueueJobSync';
    EntitySetName = 'enqueueJobSyncs';
    SourceTable = "ELCA CRM Sync. Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                field(crmId; Rec."CRM ID")
                {
                    ApplicationArea = Api;
                }
                field(sourceTableId; Rec."Source Table ID")
                {
                    ApplicationArea = Api;
                }
                field(direction; Rec.Direction)
                {
                    ApplicationArea = Api;
                }
                field(enqueueSyncResult; Result)
                {
                    ApplicationArea = Api;
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        UnsupportedMethod();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        RegisterConnection();
        exit(Execute());
    end;

    var
        Result: Boolean;
        NoRecordFoundErr: Label 'No mapping record found.';
        UnsupportedMethodErr: Label 'This method is not supported.';

    local procedure Execute(): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";

        RecordID: RecordId;
    begin
        if not CRMIntegrationRecord.FindRecordIDFromID(Rec."CRM ID", Rec."Source Table ID", RecordID) then
            Error(NoRecordFoundErr);

        CRMIntegrationManagement.GetIntegrationTableMapping(IntegrationTableMapping, RecordID);
        Result := CRMIntegrationManagement.EnqueueSyncJob(IntegrationTableMapping, RecordID, Rec."CRM ID", Rec.Direction);

        exit(Result);
    end;

    /// <summary>
    /// Register the connection to the CRM system if it is not already registered.
    /// Avoid issue table connection for table type CRM must be registered before using.
    /// </summary>
    local procedure RegisterConnection()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        CRMConnectionSetup.RegisterConnection();
    end;

    local procedure UnsupportedMethod()
    begin
        Error(UnsupportedMethodErr);
    end;
}
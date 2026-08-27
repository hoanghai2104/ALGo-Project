pageextension 50118 ShipToAddress extends "Ship-to Address List"
{
    layout
    {
        // Add changes to page layout here
        addafter("Location Code")
        {
            field("Coupled to Dataverse"; Rec."Coupled to Dataverse")
            {
                ApplicationArea = all;
                Enabled = false;
            }
        }
    }

    actions
    {
        // Add changes to page actions here

    }

    var
        CurrentlyCoupledCDSLabBook: Record "Ship-to Address";

    // trigger OnNewRecord()
    // begin
    //     Codeunit.Run(Codeunit::"CRM Integration Management");
    // end;

    // trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    // begin
    //     Codeunit.Run(Codeunit::"CRM Integration Management");
    // end;

    trigger OnOpenPage()
    begin
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
        if CDSIntegrationEnabled then
            Codeunit.Run(Codeunit::"CRM Integration Management");

    end;


    trigger OnAfterGetCurrRecord()
    begin
        if CDSIntegrationEnabled then
            CDSIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
    end;

    procedure SetCurrentlyCoupledCDSLabBook(CDSLabBook: Record "CDS msdyn_FunctionalLocation")
    begin
        CurrentlyCoupledCDSLabBook := Rec;
    end;

    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        CDSIntegrationEnabled: Boolean;
        CDSIsCoupledToRecord: Boolean;
}
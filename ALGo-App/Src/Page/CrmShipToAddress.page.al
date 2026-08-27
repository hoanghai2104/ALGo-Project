namespace Marechal.DataverseMapping.CRM;

using Microsoft.Integration.Dataverse;
using Microsoft.Service.Item;
#pragma warning disable AL0897
using Microsoft.Integration.D365Sales;
#pragma warning restore AL0897
using Microsoft.Sales.Customer;
using System.Environment.Configuration;


page 50300 "CrmShipToAddress"

{
    ApplicationArea = Suite;
    Caption = 'Crm Ship To Address';
    Editable = false;
    PageType = List;
    SourceTable = "CDS msdyn_FunctionalLocation";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(msdyn_FunctionalLocationId; Rec.msdyn_FunctionalLocationId)
                {
                    ApplicationArea = Suite;
                    Caption = 'msdyn_FunctionalLocationId';
                    ToolTip = 'Specifies the customer asset tag.';
                    StyleExpr = FirstColumnStyle;
                }
                field(Name; rec.msdyn_Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Name';
                    StyleExpr = FirstColumnStyle;

                }
                field(CustomerName; Rec.phma_Compte)
                {
                    ApplicationArea = Suite;
                    Caption = 'Customer Name';
                    ToolTip = 'Specifies the name of the customer.';
                }
                field(Coupled; Coupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled';
                    ToolTip = 'Specifies if the Dynamics 365 Field Service record is coupled to Business Central.';
                }


            }
        }
    }

    actions
    {
        area(processing)
        {
            // action(CreateFromFS)
            // {
            //     ApplicationArea = Suite;
            //     Caption = 'Create in Business Central';
            //     Image = NewItemNonStock;
            //     ToolTip = 'Generate the entity from the Field Service customer asset.';
            //     Visible = ShowCreateInBC;

            //     trigger OnAction()
            //     var
            //         CDSFunctionalLocation: Record "CDS msdyn_FunctionalLocation";
            //         CRMIntegrationManagement: Codeunit "CRM Integration Management";
            //     begin
            //         CurrPage.SetSelectionFilter(CDSFunctionalLocation);
            //         CRMIntegrationManagement.CreateNewRecordsFromSelectedCRMRecords(CDSFunctionalLocation);
            //     end;
            // }
            action(ShowOnlyUncoupled)
            {
                ApplicationArea = Suite;
                Caption = 'Hide Coupled Records';
                Image = FilterLines;
                ToolTip = 'Do not show coupled records.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(true);
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = Suite;
                Caption = 'Show Coupled Records';
                Image = ClearFilter;
                ToolTip = 'Show coupled records.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                // actionref(CreateFromFS_Promoted; CreateFromFS)
                // {
                // }
                actionref(ShowOnlyUncoupled_Promoted; ShowOnlyUncoupled)
                {
                }
                actionref(ShowAll_Promoted; ShowAll)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        // CRMAccount: Record "CRM Account";
        RecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(Rec.msdyn_FunctionalLocationId, Database::"Ship-to Address", RecordID) then
            if CurrentlyCoupledShipToAddress.msdyn_FunctionalLocationId = Rec.msdyn_FunctionalLocationId then begin
                Coupled := 'Current';
                FirstColumnStyle := 'Strong';
                Rec.Mark(true);
            end else begin
                Coupled := 'Yes';
                FirstColumnStyle := 'Subordinate';
                Rec.Mark(false);
            end
        else begin
            Coupled := 'No';
            FirstColumnStyle := 'None';
            Rec.Mark(true);
        end;

    end;

    trigger OnInit()
    begin
        Codeunit.Run(Codeunit::"CRM Integration Management");
    end;

    trigger OnOpenPage()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LookupCRMTables: Codeunit "Lookup CRM Tables";
    begin
        Rec.FilterGroup(4);
        Rec.SetView(LookupCRMTables.GetIntegrationTableMappingView(Database::"CDS msdyn_FunctionalLocation"));
        Rec.FilterGroup(0);
#pragma warning disable AA0206
        ShowCreateInBC := ApplicationAreaMgmtFacade.IsPremiumExperienceEnabled();
#pragma warning restore AA0206
    end;

    var
        CurrentlyCoupledShipToAddress: Record "CDS msdyn_FunctionalLocation";
        Coupled: Text;
        FirstColumnStyle: Text;
        ShowCreateInBC: Boolean;

    procedure SetCurrentlyCoupledShipToAddress(CrmShipToAdd: Record "CDS msdyn_FunctionalLocation")
    begin
        CurrentlyCoupledShipToAddress := CrmShipToAdd;
    end;
}


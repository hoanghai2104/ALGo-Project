page 50109 "DetailReceptionAchat"
{
    PageType = List;
    ApplicationArea = All;
    // UsageCategory = Lists;
    SourceTable = DetailReceptionAchat;
    Caption = 'Etiquettes réception';

    InsertAllowed = false;
    // ModifyAllowed = false;
    // DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(EntryNo; Rec.EntryNo)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number.';
                    Editable = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the posting date.';
                }
                field("Posted Purch Receipt No"; Rec."Posted Purch Receipt No")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posted purchase receipt number.';
                }
                field("ItemNo"; Rec."ItemNo")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item number.';
                }
                field("Désignation de l'article"; Rec."Désignation de l'article")
                {
                    ApplicationArea = all;
                }
                field(Instructions; Rec.Instructions)
                {
                    ApplicationArea = All;
                }
                field("Quantity"; Rec."Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity.';
                }
                field("DocumentNo"; Rec.DocumentNo)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document number.';
                }
                field("DocumentType"; Rec."Phma document order type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document type.';
                }
                field("Purchase Order No"; Rec."Purchase Order No")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the purchase order number.';
                    Lookup = false;
                }
                field(CustomerSearchName; Rec.CustomerSearchName)
                {
                    ApplicationArea = all;
                }
                field(VendorSearchName; Rec.VendorSearchName)
                {
                    ApplicationArea = all;
                }

                field("InterventionNo"; Rec."No de intervention")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the intervention number.';

                }
                field("TechnicianName"; Rec."TechnicianName")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the technician name.';

                }
                field("OrderGiverName"; Rec."OrderGiverName")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the order giver name.';

                }
                field("TenantName"; Rec."TenantName")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the tenant name.';

                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = All;

                }
                field("Reference Libre"; Rec."Reference Libre")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the free reference.';

                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Print)
            {
                ApplicationArea = All;
                Caption = 'Print';
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Print Selected record.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Use the new Print action in Detail Reception Achat page.';

                trigger OnAction()
                var
                    receptionAchatRecord: Record DetailReceptionAchat;
                    RecRefToPrint: RecordRef;
                    RecVarToPrint: Variant;
                    IsGUI: Boolean;
                begin
                    CurrPage.SetSelectionFilter(receptionAchatRecord);
                    RecRefToPrint := receptionAchatRecord;
                    RecVarToPrint := RecRefToPrint;
                    IsGUI := true;
                    REPORT.RunModal(Report::EtiquettesReception, IsGUI, false, RecVarToPrint);
                end;
            }
        }
    }
}

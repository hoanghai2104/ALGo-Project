pageextension 50143 "Purch. Order Subform Ext." extends "Purchase Order Subform"
{
    layout
    {
        addlast(Control1)
        {
            field("Phma source Document Order No"; Rec."Phma source Document Order No")
            {
                Caption = 'Source Document Order No.';
                ApplicationArea = All;
                Editable = false;

                trigger OnAssistEdit()
                begin
                    ShowReservation();
                end;
            }
            field("Phma document order type"; Rec."Phma document order type")
            {
                Caption = 'Source Document Order Type';
                ApplicationArea = All;
                Editable = false;
            }
            field("Technitian Name"; Rec."Technitian Name")
            {
                Caption = 'Technician Name';
                ApplicationArea = All;
                Editable = false;
            }
            field("Phma Customer Name"; Rec."Phma Customer Name")
            {
                Caption = 'Customer Name';
                ApplicationArea = All;
                Editable = false;
            }
            field("No de intervention"; Rec."No de intervention")
            {
                Caption = 'Intervention No.';
                ApplicationArea = All;
                Editable = false;
            }
            field(TenantName; Rec.TenantName)
            {
                Caption = 'Tenant Name';
                ApplicationArea = All;
                Editable = false;
            }
        }

        modify("Description 2")
        {
            Visible = true;
        }
    }

    local procedure ShowReservation()
    var
        Reservation: Page Reservation;
    begin
        Rec.Find();
        Rec.ShowReservation();

        RefreshPage();
    end;

    local procedure ShowSalesServiceOrderWorksheet()
    var
        SalesServiceOrderWorksheet: Page "Sales/Service Order Worksheet";
    begin
        SalesServiceOrderWorksheet.SetPurchaseLineProfile(Rec);
        SalesServiceOrderWorksheet.RunModal();
    end;

    local procedure RefreshPage()
    begin
        Rec.Find();
        CurrPage.Update(false);
    end;
}
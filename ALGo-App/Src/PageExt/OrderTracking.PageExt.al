pageextension 50121 OrderTracking extends "Order Tracking"
{
    layout
    {
        // Add changes to page layout here
        addafter("Supplied by")
        {
            field("N° de l’intervention"; Rec."No de intervention")
            {
                ApplicationArea = All;
            }
            field(TechnitianName; Rec."Technitian Name")
            {
                ApplicationArea = All;
                Caption = 'Nom du technicien';
            }


        }

    }

    actions
    {
        // Add changes to page actions here
    }

    trigger OnOpenPage()
    begin

        // Rec.Modify();
    end;

}
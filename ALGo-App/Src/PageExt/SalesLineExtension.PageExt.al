pageextension 50108 SalesLineExtension extends "Sales Lines"
{

    layout
    {
        addlast(Control1)
        {
            field("% OB"; Rec."% OB")
            {
                ApplicationArea = All;
            }

            field("Montant OB ligne"; Rec."Montant OB ligne")
            {
                ApplicationArea = All;
            }
        }
    }
}
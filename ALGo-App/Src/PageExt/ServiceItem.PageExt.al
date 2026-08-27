pageextension 50140 ServiceItem extends "Service Item Card"
{
    layout
    {
        // Add changes to page layout here
        addlast(Detail)
        {
            field("Date installation actif"; Rec."Date installation actif")
            {
                ApplicationArea = all;
            }
        }
        // modify("Installation Date")
        // {
        //     Visible = false;
        // }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}
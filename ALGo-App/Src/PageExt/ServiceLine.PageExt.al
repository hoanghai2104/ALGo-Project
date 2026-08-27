
pageextension 50141 ServiceLines extends "Service Lines"
{
    layout
    {
        // Add changes to page layout here
        addafter(Description)
        {
            field("Description Supp."; Rec."Description Supp.")
            {
                ApplicationArea = all;
            }
        }
        addafter("No.")
        {
            field("To Order PHM"; Rec."To Order PHM")
            {
                Caption = 'To Order';
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}
pageextension 50138 ServiceQuoteLines extends "Service Quote Lines"
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
    }

    actions
    {
        // Add changes to page actions here
    }

}
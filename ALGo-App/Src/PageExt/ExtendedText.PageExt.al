pageextension 50120 ExtendedText extends "Extended Text"
{
    layout
    {
        // Add changes to page layout here
        addlast(Sales)
        {
            field(Soumission; Rec.Soumission)
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
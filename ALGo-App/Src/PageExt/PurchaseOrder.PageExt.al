pageextension 50122 PurchaseOrder extends "Purchase Order"
{
    layout
    {
        // Add changes to page layout here
        addlast(General)
        {
            field("N° de l’intervention"; Rec."No de intervention")
            {
                ApplicationArea = all;
            }
            field(TechnitianName; Rec.TechnitianName)
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
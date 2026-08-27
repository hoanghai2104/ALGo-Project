pageextension 50100 Customercard extends Microsoft.Sales.Customer."Customer Card"
{
    layout
    {
        addlast(General)
        {
            field("Global Dimension 1"; Rec."Global Dimension 1 Code")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Global Dimension 1';
            }
        }
    }
}

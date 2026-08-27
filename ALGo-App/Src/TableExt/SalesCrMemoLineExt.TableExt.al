tableextension 50104 SalesCrMemoLineExt extends "Sales Cr.Memo Line"
{
    AllowInCustomizations = AsReadOnly;

    fields
    {
        // Add changes to table fields here
        field(50103; "Description Supp."; Text[500])
        {
            Caption = 'Description Supp.';
        }

        field(50100; "% OB"; Decimal)
        {
            Caption = '% OB';
        }

        field(50101; "Montant OB ligne"; Decimal)
        {
            Caption = 'Montant OB ligne';
        }
        field(50104; "% Remise articles"; Decimal)
        {

        }
        field(50105; "Remise article amount"; Decimal)
        {

        }
    }

}
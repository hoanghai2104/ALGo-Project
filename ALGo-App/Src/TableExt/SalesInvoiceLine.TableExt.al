tableextension 50102 SalesInvoiceLine extends "Sales Invoice Line"
{
    AllowInCustomizations = AsReadOnly;

    fields
    {
        // Add changes to table fields here
        field(50102; "Code RPLP"; Integer)
        {
            TableRelation = RplpParametrage."Code ID";
            BlankZero = true;
        }

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
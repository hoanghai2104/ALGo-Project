tableextension 50126 ServiceCrMemoLine extends "Service Cr.Memo Line"
{
    fields
    {
        // Add changes to table fields here
        field(50101; "Description Supp."; Text[500])
        {
            Caption = 'Description Supp.';
            //DataClassification = CustomerContent; // Utilise approprié: CustomerContent, ToBeClassified, etc.
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }


}
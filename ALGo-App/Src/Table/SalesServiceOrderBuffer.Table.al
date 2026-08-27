table 50108 "Sales/Service Order Buffer"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Document Type"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(3; "Customer No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(4; "Customer Name"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Intervention No."; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(6; "Technician Name"; Code[100])
        {
            DataClassification = ToBeClassified;
        }
        field(7; "Tenant Name"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Document Type", "Document No.")
        {
            Clustered = true;
        }
    }
}
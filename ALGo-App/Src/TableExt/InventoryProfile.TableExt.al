tableextension 50127 InventoryProfile extends "Inventory Profile"
{
    fields
    {
        // Add changes to table fields here
        field(50102; "N° de l’intervention"; text[100])
        {

        }
        field(50103; TechnitianName; Code[20])
        {
            Caption = 'Nom du technicien';
            TableRelation = Resource.Name;
            ValidateTableRelation = false;

        }
        field(50100; "Phma source Document Order No"; Code[20])
        {

        }
        field(50101; "Phma Customer Name"; Text[100])
        {

        }
        field(50104; "Phma document order type"; Text[100])
        {

        }
        field(50107; "TenantName"; Text[100])
        {
            Caption = 'Nom du Locataire';
            DataClassification = ToBeClassified;
        }
        field(50105; "Nom du technicien"; Code[100])
        {
            Caption = 'Nom du technicien';
        }

        field(50108; "Source Document Line No."; Integer)
        {
            Caption = 'Source Document Line No.';
            DataClassification = ToBeClassified;
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
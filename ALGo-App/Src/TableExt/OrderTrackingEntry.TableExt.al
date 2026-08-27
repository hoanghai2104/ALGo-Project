tableextension 50113 OrderTrackingEntry extends "Order Tracking Entry"
{
    AllowInCustomizations = AsReadOnly;

    fields
    {
        // Add changes to table fields here
        field(50100; "N° de l’intervention"; Code[20])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by Text[100] field.';
        }

        field(50101; TechnitianName; Code[20])
        {
            Caption = 'Nom du technicien';
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by Text[100] field.';

        }
        field(50102; "No de intervention"; Text[100])
        {
            Caption = 'N° de l’intervention';
        }
        field(50103; "Technitian Name"; Text[100])
        {
            Caption = 'Nom du technicien';

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
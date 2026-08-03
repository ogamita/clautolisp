// all-widgets.dcl -- one of every standard DCL tile type.
//
// Standard DCL only: this file loads unchanged in AutoCAD, BricsCAD and
// clautolisp (both the GUI and the terminal/TUI renderer). No clautolisp
// extensions are used, so the SAME dialog drives the SAME report in every
// environment (see all-widgets.lsp and README.org).

all_widgets : dialog {
  label = "All Widgets";

  : text { key = "hdr"; label = "Every standard DCL tile, exactly once."; }

  : boxed_column {
    label = "Text and edit";
    : text { key = "info"; label = "This is a read-only text tile."; }
    : edit_box { key = "name"; label = "Name:"; edit_width = 20; }
  }

  : boxed_row {
    label = "Toggle and popup";
    : toggle { key = "shout"; label = "Shout?"; }
    : popup_list { key = "colour"; label = "Colour:"; }
  }

  : boxed_column {
    label = "Radio group";
    : radio_column {
      key = "size";
      : radio_button { key = "small";  label = "Small";  }
      : radio_button { key = "medium"; label = "Medium"; }
      : radio_button { key = "large";  label = "Large";  }
    }
  }

  : boxed_column {
    label = "List";
    : list_box { key = "fruit"; label = "Fruit:"; height = 4; }
  }

  : boxed_row {
    label = "Slider and images";
    : slider { key = "volume"; label = "Volume:"; min_value = 0; max_value = 10; }
    : image { key = "swatch"; width = 8; height = 3; color = 1; }
    : image_button { key = "logo"; width = 8; height = 3; color = 2; }
  }

  : spacer { height = 1; }

  : button { key = "reset"; label = "Reset defaults"; }

  : ok_cancel;
}

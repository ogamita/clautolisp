greet : dialog {
  label = "Greeting";
  : text { label = "Enter your name:"; }
  : edit_box { key = "name"; label = "Name"; edit_width = 30; }
  : toggle { key = "shout"; label = "Shout?"; }
  : ok_cancel;
}

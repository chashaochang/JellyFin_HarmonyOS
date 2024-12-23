class Theme{
  colors:Colors = new Colors()
}

export class Colors {
  background = 0xFF101010
  error = 0xFFFF0000
  surface = 0xFF363636
}

const theme = new Theme()
export default theme
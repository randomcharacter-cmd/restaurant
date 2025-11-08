# L'Olivar Vell Restaurant Website

A modern, professional static website for L'Olivar Vell, an authentic Mediterranean restaurant in Barcelona.

## Features

### Core Functionality
- **Bilingual Support**: Full English and Spanish translations with easy language switching
- **Responsive Design**: Optimized for desktop, tablet, and mobile devices
- **Modern UI/UX**: Clean, professional design with smooth animations and transitions
- **Fast Loading**: Optimized for rapid page loads with efficient CSS and minimal JavaScript

### Sections

1. **Hero Section**
   - Eye-catching background image
   - Clear call-to-action button

2. **About**
   - Brief introduction to the restaurant

3. **Menu**
   - Three categories: Starters, Main Courses, Desserts
   - Each dish includes:
     - Professional food photography (via Unsplash)
     - Name and description in both languages
     - Price in Euros
   - Interactive category switching

4. **Gallery**
   - Beautiful photo gallery showcasing the restaurant's ambience
   - Hover effects for enhanced interactivity

5. **Customer Reviews**
   - 5-star reviews from satisfied customers
   - Elegant card design

6. **Reservations**
   - Interactive reservation form with:
     - Date picker (minimum date: today)
     - Time selection dropdown
     - Guest count selector
     - Name and email fields
   - Success confirmation message (no backend - demonstration only)

7. **Contact & Location**
   - Opening hours (Monday-Sunday)
   - Contact information:
     - Address: Carrer de la Palla, 18, 08002 Barcelona, Spain
     - Phone: +34 933 18 42 67
     - Email: info@olivarvell.com
   - Embedded Google Maps iframe

8. **Footer**
   - Quick navigation links
   - Branding and copyright information

## Technologies Used

- **HTML5**: Semantic markup for better accessibility and SEO
- **CSS3**: Modern styling with:
  - CSS Grid and Flexbox for layouts
  - CSS Variables for easy theming
  - Smooth animations and transitions
  - Media queries for responsive design
- **Vanilla JavaScript**:
  - Language switching
  - Form handling
  - Smooth scrolling
  - Mobile menu toggle
  - Intersection Observer API for scroll animations

## File Structure

```
restaurant/
├── index.html          # Main HTML file
├── styles.css          # All styles
├── script.js           # JavaScript functionality
└── README.md           # This file
```

## Getting Started

1. Simply open `index.html` in a web browser
2. No build process or dependencies required
3. All images are loaded from Unsplash CDN

## Browser Compatibility

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
- Mobile browsers (iOS Safari, Chrome Mobile)

## Design Highlights

### Color Palette
- Primary: Deep Green (#2c5f2d) - represents fresh Mediterranean ingredients
- Secondary: Olive Green (#97a74f) - pays homage to the restaurant name
- Accent: Golden Beige (#d4a574) - adds warmth and elegance

### Typography
- Headings: Playfair Display (serif) - elegant and classic
- Body: Lato (sans-serif) - clean and readable

### Performance Optimizations
- Lazy loading support for images
- Efficient CSS selectors
- Minimal JavaScript
- Optimized animations with `will-change` property
- CDN-hosted images for faster loading

## Customization

To customize the website:

1. **Change colors**: Modify CSS variables in `:root` in `styles.css`
2. **Update content**: Edit text in `index.html` and translations in `script.js`
3. **Replace images**: Update image URLs in `index.html` (use Unsplash or upload your own)
4. **Modify menu**: Edit menu items in the HTML and add corresponding translations

## Future Enhancements

Potential additions if backend functionality is needed:
- Real reservation system with database
- Email confirmation for reservations
- Online ordering system
- Admin panel for menu management
- Newsletter subscription
- Blog section

## License

This is a demonstration project for L'Olivar Vell restaurant.

## Credits

- Food and restaurant images: [Unsplash](https://unsplash.com)
- Fonts: Google Fonts (Playfair Display, Lato)

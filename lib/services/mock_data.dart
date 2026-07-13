import '../models/models.dart';
import '../utils/theme.dart';

const Map<String, String> _photoIds = {
  'biryani': '1631515243349-e0cb75fb8d3a',
  'paneer': '1631452180519-c014fe946bc7',
  'haleem': '1547928576-b822bc410bdf',
  'curry': '1565557623262-b51c2513a641',
  'gulab': '1571877227200-a0d98ea607e9',
  'lassi': '1461023058943-07fcbe16d735',
};

String foodImageUrl(String key, {int width = 520}) {
  final id = _photoIds[key] ?? _photoIds['biryani']!;
  return 'https://images.unsplash.com/photo-$id?w=$width&q=80&auto=format&fit=crop';
}

const restaurantName = 'Paradise Biryani';
const restaurantLocationLine = 'Banjara Hills · Outlet #402';
const restaurantInitials = 'PB';

const List<MenuItem> menuItems = [
  MenuItem(id: 'biryani', section: 'Biryani', name: 'Chicken Dum Biryani', basePrice: 320, veg: false, soldThisWeek: 128, photoKey: 'biryani'),
  MenuItem(id: 'haleem', section: 'Biryani', name: 'Hyderabadi Haleem', basePrice: 340, veg: false, soldThisWeek: 54, photoKey: 'haleem', baseAvail: false),
  MenuItem(id: 'paneer', section: 'Main Course', name: 'Paneer Butter Masala', basePrice: 280, veg: true, soldThisWeek: 86, photoKey: 'paneer'),
  MenuItem(id: 'naan', section: 'Breads', name: 'Butter Naan', basePrice: 60, veg: true, soldThisWeek: 210, photoKey: 'curry'),
  MenuItem(id: 'gulab', section: 'Desserts', name: 'Gulab Jamun (2 pcs)', basePrice: 90, veg: true, soldThisWeek: 141, photoKey: 'gulab'),
  MenuItem(id: 'lassi', section: 'Beverages', name: 'Sweet Lassi', basePrice: 80, veg: true, soldThisWeek: 33, photoKey: 'lassi', baseAvail: false),
];

const List<String> menuSectionOrder = ['Biryani', 'Main Course', 'Breads', 'Desserts', 'Beverages'];

MenuItem menuItemById(String id) => menuItems.firstWhere((m) => m.id == id);

List<Order> seedOrders() => [
      const Order(
        id: 'FZ8842',
        status: OrderStatus.incoming,
        type: OrderType.delivery,
        customer: 'Aarav Mehta',
        dist: '2.1 km',
        placed: 'Just now',
        prepMinutes: 20,
        payLabel: 'Paid · UPI',
        lines: [
          OrderLine(name: 'Chicken Dum Biryani', qty: 2, price: 320, veg: false),
          OrderLine(name: 'Gulab Jamun (2 pcs)', qty: 1, price: 90, veg: true),
        ],
      ),
      const Order(
        id: 'FZ8840',
        status: OrderStatus.preparing,
        type: OrderType.delivery,
        customer: 'Sneha Reddy',
        dist: '1.4 km',
        placed: '6 min ago',
        prepMinutes: 14,
        payLabel: 'Paid · Card',
        lines: [
          OrderLine(name: 'Paneer Butter Masala', qty: 1, price: 280, veg: true),
          OrderLine(name: 'Butter Naan', qty: 3, price: 60, veg: true),
        ],
      ),
      const Order(
        id: 'FZ8839',
        status: OrderStatus.preparing,
        type: OrderType.takeaway,
        customer: 'Imran Khan',
        dist: '',
        placed: '9 min ago',
        prepMinutes: 8,
        payLabel: 'Paid · Wallet',
        lines: [OrderLine(name: 'Hyderabadi Haleem', qty: 2, price: 340, veg: false)],
      ),
      const Order(
        id: 'FZ8836',
        status: OrderStatus.ready,
        type: OrderType.delivery,
        customer: 'Divya S.',
        dist: '3.0 km',
        placed: '18 min ago',
        prepMinutes: 0,
        payLabel: 'COD',
        lines: [
          OrderLine(name: 'Chicken Dum Biryani', qty: 1, price: 320, veg: false),
          OrderLine(name: 'Sweet Lassi', qty: 2, price: 80, veg: true),
        ],
      ),
      const Order(
        id: 'FZ8831',
        status: OrderStatus.completed,
        type: OrderType.delivery,
        customer: 'Rahul V.',
        dist: '2.6 km',
        placed: '40 min ago',
        prepMinutes: 0,
        payLabel: 'Paid · UPI',
        lines: [OrderLine(name: 'Paneer Butter Masala', qty: 2, price: 280, veg: true)],
      ),
    ];

/// Demo pool that `simulate()` cycles through to fabricate a new incoming order.
const List<Order> simulationPool = [
  Order(
    id: '',
    status: OrderStatus.incoming,
    type: OrderType.delivery,
    customer: 'Kavya N.',
    dist: '1.8 km',
    placed: 'Just now',
    prepMinutes: 18,
    payLabel: 'Paid · UPI',
    lines: [
      OrderLine(name: 'Chicken Dum Biryani', qty: 1, price: 320, veg: false),
      OrderLine(name: 'Sweet Lassi', qty: 1, price: 80, veg: true),
    ],
  ),
  Order(
    id: '',
    status: OrderStatus.incoming,
    type: OrderType.takeaway,
    customer: 'Rohit B.',
    dist: '',
    placed: 'Just now',
    prepMinutes: 12,
    payLabel: 'Paid · Card',
    lines: [
      OrderLine(name: 'Paneer Butter Masala', qty: 2, price: 280, veg: true),
      OrderLine(name: 'Butter Naan', qty: 4, price: 60, veg: true),
    ],
  ),
  Order(
    id: '',
    status: OrderStatus.incoming,
    type: OrderType.delivery,
    customer: 'Meera J.',
    dist: '2.9 km',
    placed: 'Just now',
    prepMinutes: 22,
    payLabel: 'COD',
    lines: [
      OrderLine(name: 'Hyderabadi Haleem', qty: 1, price: 340, veg: false),
      OrderLine(name: 'Gulab Jamun (2 pcs)', qty: 2, price: 90, veg: true),
    ],
  ),
];

List<TableBooking> seedBookings() => const [
      TableBooking(id: 'TBL2291', name: 'Ananya Rao', date: 'Today', time: '8:30 PM', party: 4, ref: 'Window booth', status: 'Confirmed', paid: true, amount: 500, note: 'Advance paid via Foodeez'),
      TableBooking(id: 'TBL2288', name: 'Vikram Sethi', date: 'Today', time: '9:15 PM', party: 2, ref: 'Any table', status: 'Confirmed', paid: false, amount: 0, note: 'Pay at restaurant'),
      TableBooking(id: 'TBL2280', name: 'Priya & family', date: 'Tomorrow', time: '1:00 PM', party: 6, ref: 'Private area', status: 'Confirmed', paid: true, amount: 1000, note: 'Advance paid via Foodeez'),
      TableBooking(id: 'TBL2274', name: 'Rohit Bhatt', date: '8 Jul', time: '8:00 PM', party: 3, ref: 'Table 7', status: 'Completed', paid: true, amount: 500, note: 'Advance adjusted in bill'),
      TableBooking(id: 'TBL2270', name: 'Sana Kapoor', date: '7 Jul', time: '7:30 PM', party: 2, ref: 'Any table', status: 'Cancelled', paid: true, amount: 500, note: 'Refunded to source'),
    ];

List<PaymentTxn> seedPayments() => const [
      PaymentTxn(id: 'PAYONB', label: 'Onboarding fee (launch offer)', method: 'UPI', amount: 1, when: '2 Jul, 5:12 PM', kind: 'paid'),
      PaymentTxn(id: 'PAY9921', label: 'Table advance · Ananya Rao', method: 'UPI', amount: 500, when: 'Today, 2:10 PM', kind: 'credit'),
      PaymentTxn(id: 'PAY9918', label: 'Table advance · Priya & family', method: 'Card', amount: 1000, when: 'Today, 11:42 AM', kind: 'credit'),
      PaymentTxn(id: 'PAY9910', label: 'Order #FZ8831 · Rahul V.', method: 'UPI', amount: 560, when: 'Today, 10:05 AM', kind: 'credit'),
      PaymentTxn(id: 'PAY9902', label: 'Table advance · Rohit Bhatt', method: 'Card', amount: 500, when: '8 Jul, 8:22 PM', kind: 'credit'),
      PaymentTxn(id: 'PAY9898', label: 'Refund · Sana Kapoor (cancelled)', method: 'UPI', amount: 500, when: '7 Jul, 9:10 PM', kind: 'debit'),
    ];

List<Review> seedReviews() => const [
      Review(name: 'Aarav M.', rating: 5, when: '2 days ago', item: 'Chicken Dum Biryani', text: 'Biryani was perfectly cooked, rich flavour and generous portion. Delivery was quick too!'),
      Review(name: 'Sneha R.', rating: 4, when: '3 days ago', item: 'Paneer Butter Masala', text: 'Great taste but the naan came slightly cold. Everything else was spot on.', reply: 'Thanks Sneha! We will pack breads hotter next time.'),
      Review(name: 'Imran K.', rating: 5, when: '5 days ago', item: 'Hyderabadi Haleem', text: 'The best haleem in the city. Consistent quality every single time.'),
      Review(name: 'Divya S.', rating: 3, when: '1 week ago', item: 'Chicken Dum Biryani', text: 'Tasted good but the portion felt a bit smaller than before.'),
    ];

List<RestaurantOffer> seedOffers() => const [
      RestaurantOffer(title: '50% OFF', sub: 'Up to ₹100 · new customers, first order', code: 'WELCOME50', gradient: [AppColors.accent, AppColors.accentLight], live: true, redeemed: 342),
      RestaurantOffer(title: 'Flat ₹150 OFF', sub: 'On orders above ₹599', code: 'FEAST150', gradient: [AppColors.gold, AppColors.goldDark], live: true, redeemed: 98),
      RestaurantOffer(title: 'Free Gulab Jamun', sub: 'On orders above ₹399', code: 'SWEETPB', gradient: [AppColors.accentDeep, AppColors.accentDeep2], live: false, redeemed: 410),
    ];

/// Tier `n` (1-10) → flat daily subscription fee, capped at ₹999/day.
const List<int> tierFees = [129, 229, 329, 429, 529, 629, 729, 829, 929, 999];

const List<SubscriptionTier> subscriptionTiers = [
  SubscriptionTier(n: 1, range: '0–9', fee: 129),
  SubscriptionTier(n: 2, range: '10–19', fee: 229),
  SubscriptionTier(n: 3, range: '20–29', fee: 329),
  SubscriptionTier(n: 4, range: '30–39', fee: 429),
  SubscriptionTier(n: 5, range: '40–49', fee: 529),
  SubscriptionTier(n: 6, range: '50–59', fee: 629),
  SubscriptionTier(n: 7, range: '60–69', fee: 729),
  SubscriptionTier(n: 8, range: '70–79', fee: 829),
  SubscriptionTier(n: 9, range: '80–89', fee: 929),
  SubscriptionTier(n: 10, range: '90+', fee: 999),
];

int tierOf(int ordersToday) => (ordersToday ~/ 10 + 1).clamp(1, 10);

int tierFeeFor(int ordersToday) => tierFees[tierOf(ordersToday) - 1];

/// Last 7 days of daily-tier history shown on the Subscription screen.
/// The final entry ("Today") is replaced with the live order count at render time.
const List<({String day, int orders})> subscriptionDayHistory = [
  (day: 'Wed', orders: 22),
  (day: 'Thu', orders: 26),
  (day: 'Fri', orders: 48),
  (day: 'Sat', orders: 61),
  (day: 'Sun', orders: 58),
  (day: 'Mon', orders: 30),
];

const List<({String range, String customer, String restaurant})> deliverySlabs = [
  (range: '0–3 km', customer: '₹25', restaurant: '₹0'),
  (range: '3–6 km', customer: '₹35–₹45', restaurant: '₹0'),
  (range: 'Surge (rain / festival)', customer: '+₹10–₹20', restaurant: '₹0'),
  (range: 'Your own riders', customer: 'You set it', restaurant: '₹0'),
];

/// Earnings figures for Today are derived live from `doneToday`/`gmvToday` in
/// OrdersController; This week / This month are fixed demo figures matching the design.
const EarningsPeriod earningsWeek = EarningsPeriod(label: 'This week', span: '7–13 Jul', orders: 238, gmv: 83300, subscriptionFee: 3150, subNote: '7 daily tiers');
const EarningsPeriod earningsMonth = EarningsPeriod(label: 'This month', span: 'July 2025', orders: 1020, gmv: 357000, subscriptionFee: 13020, subNote: '31 daily tiers');

List<Settlement> seedSettlements() => const [
      Settlement(id: 'S1', week: 'Mon, 8 Jul', date: 'Paid 9 Jul · 8:02 AM', agoDays: 1, orders: 31, tierLabel: 'Tier 4', itemSales: 11800, packaging: 620, gst: 590, discount: 940, ads: 180, delivery: 210, subscriptionFee: 429, tcs: 118, tds: 12),
      Settlement(id: 'S2', week: 'Sun, 7 Jul', date: 'Paid 8 Jul · 8:01 AM', agoDays: 2, orders: 52, tierLabel: 'Tier 6', itemSales: 15200, packaging: 840, gst: 760, discount: 1360, ads: 250, delivery: 320, subscriptionFee: 629, tcs: 152, tds: 15),
      Settlement(id: 'S3', week: 'Sat, 6 Jul', date: 'Paid 7 Jul · 8:03 AM', agoDays: 3, orders: 63, tierLabel: 'Tier 7', itemSales: 17900, packaging: 980, gst: 895, discount: 1610, ads: 300, delivery: 390, subscriptionFee: 729, tcs: 179, tds: 18),
      Settlement(id: 'S4', week: 'Fri, 5 Jul', date: 'Paid 6 Jul · 8:00 AM', agoDays: 4, orders: 44, tierLabel: 'Tier 5', itemSales: 13400, packaging: 700, gst: 670, discount: 1070, ads: 210, delivery: 260, subscriptionFee: 529, tcs: 134, tds: 13),
      Settlement(id: 'S5', week: 'Mon, 1 Jul', date: 'Paid 2 Jul · 8:02 AM', agoDays: 8, orders: 46, tierLabel: 'Tier 5', itemSales: 13950, packaging: 730, gst: 698, discount: 1120, ads: 220, delivery: 270, subscriptionFee: 529, tcs: 140, tds: 14),
      Settlement(id: 'S6', week: 'Sat, 22 Jun', date: 'Paid 23 Jun · 8:01 AM', agoDays: 17, orders: 59, tierLabel: 'Tier 7', itemSales: 16600, packaging: 900, gst: 830, discount: 1490, ads: 280, delivery: 360, subscriptionFee: 729, tcs: 166, tds: 17),
    ];

const onboardingFeeNote = 'Waived by FooDeeZ · Hyderabad first-500';

const List<({String id, String name, String desc})> reportDefs = [
  (id: 'orders', name: 'Orders report', desc: 'Every order, items, status & customer'),
  (id: 'payments', name: 'Payments & settlements', desc: 'Payouts with full deduction breakup'),
  (id: 'gst', name: 'Sales & GST report', desc: 'Taxable sales, GST, TCS & TDS'),
  (id: 'items', name: 'Item performance', desc: 'Units sold & revenue per dish'),
  (id: 'invoices', name: 'Subscription invoices', desc: 'Daily tier fees with GST invoice'),
];

const List<({String label, String value, String delta, bool up})> insightsKpis = [
  (label: 'Revenue', value: '₹2.4L', delta: '▲ 9% WoW', up: true),
  (label: 'Orders', value: '612', delta: '▲ 5% WoW', up: true),
  (label: 'Avg order value', value: '₹392', delta: '▲ ₹18', up: true),
  (label: 'Repeat customers', value: '46%', delta: '▼ 2%', up: false),
];

const List<int> salesByDayPct = [62, 48, 70, 55, 82, 100, 90];
const List<String> salesByDayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const int salesByDayTodayIndex = 5;

List<({String name, String photoKey, String count})> topSellers() => const [
      (name: 'Chicken Dum Biryani', photoKey: 'biryani', count: '128'),
      (name: 'Butter Naan', photoKey: 'curry', count: '210'),
      (name: 'Gulab Jamun', photoKey: 'gulab', count: '141'),
      (name: 'Paneer Butter Masala', photoKey: 'paneer', count: '86'),
    ];

const List<({int star, int pct})> ratingDistribution = [
  (star: 5, pct: 78),
  (star: 4, pct: 16),
  (star: 3, pct: 5),
  (star: 2, pct: 2),
  (star: 1, pct: 1),
];

const List<({String day, String time, bool open})> hoursRows = [
  (day: 'Monday', time: '11:00 AM – 11:30 PM', open: true),
  (day: 'Tuesday', time: '11:00 AM – 11:30 PM', open: true),
  (day: 'Wednesday', time: '11:00 AM – 11:30 PM', open: true),
  (day: 'Thursday', time: '11:00 AM – 11:30 PM', open: true),
  (day: 'Friday', time: '11:00 AM – 12:30 AM', open: true),
  (day: 'Saturday', time: '11:00 AM – 12:30 AM', open: true),
  (day: 'Sunday', time: 'Closed', open: false),
];

const List<({String label, String value})> addressLines = [
  (label: 'OUTLET ADDRESS', value: 'Road No. 12, Banjara Hills, Hyderabad, Telangana 500034'),
  (label: 'LANDMARK', value: 'Opposite GVK One Mall'),
  (label: 'PICKUP POINT', value: 'Rear service lane · Gate B for riders'),
  (label: 'SERVICE RADIUS', value: '6 km delivery zone'),
];

const List<({String emoji, String name, String meta, bool ok})> docsList = [
  (emoji: '🧾', name: 'FSSAI licence', meta: 'No. 13319011000287 · valid till Mar 2027', ok: true),
  (emoji: '🏛️', name: 'GST registration', meta: '36ABCDE1234F1Z5', ok: true),
  (emoji: '🪪', name: 'Owner PAN', meta: 'ABCDE1234F', ok: true),
  (emoji: '📸', name: 'Kitchen photos', meta: '6 of 8 uploaded', ok: false),
];

const List<({String emoji, String label, String sub})> supportChannels = [
  (emoji: '💬', label: 'Chat with us', sub: 'Avg reply under 2 min'),
  (emoji: '📞', label: 'Call partner desk', sub: '1800-208-9900 · 24×7'),
  (emoji: '✉️', label: 'Email support', sub: 'partners@foodeez.in'),
];

const List<({String q, String a})> supportFaqs = [
  (q: 'How do I mark an order ready?', a: 'Open the order and tap "Mark ready". The assigned rider is notified instantly.'),
  (q: 'When do I get paid?', a: "Next morning — every day. Yesterday's earnings land in your bank account by 8 AM, settled daily."),
  (q: 'An item ran out — what do I do?', a: 'Go to Menu and toggle the item to "Sold out". Customers can\'t order it until you switch it back.'),
  (q: 'How much does FooDeeZ charge?', a: 'Zero commission. Only a flat daily subscription that auto-adjusts by your order count (₹129–₹999/day, capped).'),
];

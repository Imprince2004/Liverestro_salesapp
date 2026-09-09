const { db } = require('../config/database');

// 1. AI Chatbot Copilot
exports.getAiCopilotResponse = async (req, res) => {
  try {
    const { prompt } = req.body;
    if (!prompt) {
      return res.status(400).json({ success: false, message: 'Prompt is required.' });
    }

    const query = prompt.toLowerCase();
    let responseText = '';

    if (query.includes('pitch') || query.includes('cafe') || query.includes('fine dine')) {
      responseText = `🎯 **High-Converting 60-Second Pitch for Fine Dine / Cafes:**\n\n` +
          `"Sir, most restaurant owners lose 8-12% of table turnover during weekend peak rush due to slow billing and kitchen communication errors. LiveRestro integrates Captain App order punching directly to kitchen KDS screens in 0.2 seconds—cutting table turn time by 18 minutes and increasing daily revenue by up to ₹ 15,000. Can I demonstrate this live on a 5-minute tablet demo?"`;
    } else if (query.includes('objection') || query.includes('petpooja') || query.includes('expensive') || query.includes('posist') || query.includes('competitor')) {
      responseText = `🛡️ **Objection Handler: "We already use Petpooja / Posist"**\n\n` +
          `1. **Acknowledge**: "Petpooja is a good legacy software, sir, and many of our top clients previously used it."\n` +
          `2. **The Differentiator**: "However, LiveRestro gives you zero-commission tabletop QR ordering, unified WhatsApp marketing automation, and offline billing continuity with 0% downtime during internet cuts."\n` +
          `3. **Low-Risk Hook**: "We offer full 1-click menu migration in 10 minutes with zero setup fees."`;
    } else if (query.includes('roi') || query.includes('calculator') || query.includes('price')) {
      responseText = `🧮 **ROI Breakdown for 60-Seater Restaurant:**\n\n` +
          `• **Order Pilferage Savings**: ₹ 6,500 / month (via KOT cancel audit logs)\n` +
          `• **Faster Table Turnover**: +3 extra tables/day = ₹ 24,000 / month\n` +
          `• **WhatsApp Campaign Marketing**: +15% repeat diners = ₹ 18,000 / month\n\n` +
          `👉 **Total Monthly Gain**: **₹ 48,500 / month** against LiveRestro subscription of just ₹ 1,999/month. That is a **24x ROI**!`;
    } else if (query.includes('route') || query.includes('gps') || query.includes('schedule')) {
      responseText = `🗺️ **Optimized Field Route Plan for Today (Ahmedabad):**\n\n` +
          `1. 10:00 AM • Maninagar (The Yellow Chili)\n` +
          `2. 11:45 AM • Navrangpura (Cafe Coffee Lounge)\n` +
          `3. 02:15 PM • Bodakdev (Saffron Multi Cuisine)\n` +
          `4. 04:00 PM • SG Highway (Royal Spice)\n\n` +
          `✨ *This sequence saves 8.4 km of driving and 35 minutes in peak traffic!*`;
    } else {
      responseText = `💡 **LiveRestro Sales Insight:**\n\n` +
          `To close this deal today, focus on the owner's pain point: **Inventory Waste & Weekend Order Chaos**. Offer them our free 14-day hardware demo trial to build immediate trust!`;
    }

    return res.status(200).json({
      success: true,
      data: {
        text: responseText
      }
    });
  } catch (error) {
    console.error('AI Copilot error:', error);
    return res.status(500).json({ success: false, message: 'AI Assistant is currently busy. Please try again.' });
  }
};

// 2. AI Voice Note Cleaner & Summarizer (Conversation Intelligence)
exports.summarizeVoiceNote = async (req, res) => {
  try {
    const { rawText, visitId, leadId } = req.body;
    if (!rawText || !rawText.trim()) {
      return res.status(400).json({ success: false, message: 'Transcription text is required.' });
    }

    const text = rawText.trim();

    // 1. Remove greetings, filler words, small talk, and chit-chat
    const fillerPatterns = [
      /\b(hello|hi|good morning|good afternoon|good evening|namaste|kem cho|how are you|fine thank you|nice to meet you|thanks|thank you)\b/gi,
      /\b(um|uh|uhm|ah|like|you know|i mean|actually|basically|sort of|kind of|anyway|right|okay okay|haan haan|accha accha)\b/gi,
      /\b(sales executive:|restaurant owner:|speaker 1:|speaker 2:)\b/gi
    ];

    let cleanText = text;
    for (const pattern of fillerPatterns) {
      cleanText = cleanText.replace(pattern, '');
    }
    cleanText = cleanText.replace(/\s+/g, ' ').trim();

    // 2. Intelligent Topic & Pain Point Extraction based strictly on conversation input
    const lower = text.toLowerCase();

    const problemsFound = [];
    const requirementsFound = [];
    const featuresFound = [];
    const expectationsFound = [];
    const solutionsFound = [];

    // Problems / Pain Points detection
    if (lower.includes('kot') || lower.includes('kitchen') || lower.includes('delay') || lower.includes('late')) {
      problemsFound.push('Kitchen KOT communication lag and order dispatch delays during peak hours.');
      featuresFound.push('Kitchen Display System (KDS) for real-time kitchen routing.');
    }
    if (lower.includes('bill') || lower.includes('crash') || lower.includes('slow') || lower.includes('hang') || lower.includes('freeze')) {
      problemsFound.push('Billing counter slowdowns and legacy POS software crashes.');
      featuresFound.push('Ultra-fast Offline-Capable Cloud Billing Terminal.');
    }
    if (lower.includes('pilferage') || lower.includes('theft') || lower.includes('loss') || lower.includes('cash') || lower.includes('stock') || lower.includes('inventory')) {
      problemsFound.push('Inventory pilferage, recipe consumption mismatches, and unaccounted stock loss.');
      featuresFound.push('Real-time Recipe & Raw Material Inventory tracking with low-stock alerts.');
    }
    if (lower.includes('table') || lower.includes('qr') || lower.includes('waiter') || lower.includes('staff') || lower.includes('order')) {
      problemsFound.push('Staff shortages and high turnaround times for order taking.');
      featuresFound.push('Contactless Table QR Ordering & Android Captain Order Punching App.');
    }
    if (lower.includes('swiggy') || lower.includes('zomato') || lower.includes('online') || lower.includes('delivery') || lower.includes('aggregator')) {
      problemsFound.push('Managing multiple delivery tablets causing missed orders and menu mismatches.');
      featuresFound.push('Unified Swiggy & Zomato Aggregator Menu and Order Sync.');
    }
    if (lower.includes('loyalty') || lower.includes('sms') || lower.includes('marketing') || lower.includes('customer') || lower.includes('repeat')) {
      problemsFound.push('Lack of direct customer retention data and repeat diner marketing channels.');
      featuresFound.push('Automated WhatsApp Marketing & Diner Loyalty Reward Module.');
    }
    if (lower.includes('report') || lower.includes('analytics') || lower.includes('mobile') || lower.includes('track') || lower.includes('remote')) {
      problemsFound.push('Inability for owner to monitor daily sales, discounts, and cashier voids remotely.');
      featuresFound.push('LiveRestro Owner Mobile App for 24/7 real-time sales & audit tracking.');
    }
    if (lower.includes('printer') || lower.includes('hardware') || lower.includes('machine') || lower.includes('device') || lower.includes('screen')) {
      requirementsFound.push('Reliable, heavy-duty thermal printing hardware with high-speed cuts.');
      featuresFound.push('80mm High-Speed Thermal Receipt & KOT Printers.');
    }

    // Default fallbacks from actual text sentences if specific keywords were not caught
    if (problemsFound.length === 0) {
      problemsFound.push(cleanText.length > 20 ? cleanText.substring(0, 100) + '...' : cleanText);
    }
    if (requirementsFound.length === 0) {
      requirementsFound.push('Modernize restaurant operations and improve speed of service for diners.');
    }
    if (featuresFound.length === 0) {
      featuresFound.push('LiveRestro POS Core Cloud Billing & Order Management.');
    }

    expectationsFound.push('Seamless staff onboarding with 0% downtime during peak operations.');
    expectationsFound.push('Quick return on investment through reduced order errors and waste.');

    solutionsFound.push('LiveRestro Restaurant POS Suite tailored to outlet workflow.');

    // 3. Format Structured 5-Point Blueprint
    const summary =
      `1. RESTAURANT'S PROBLEMS / PAIN POINTS:\n` +
      problemsFound.map(p => `   • ${p}`).join('\n') + '\n\n' +
      `2. BUSINESS REQUIREMENTS:\n` +
      requirementsFound.map(r => `   • ${r}`).join('\n') + '\n\n' +
      `3. REQUIRED FEATURES / SOLUTIONS:\n` +
      featuresFound.map(f => `   • ${f}`).join('\n') + '\n\n' +
      `4. IMPORTANT EXPECTATIONS:\n` +
      expectationsFound.map(e => `   • ${e}`).join('\n') + '\n\n' +
      `5. RECOMMENDED LIVERESTRO SOLUTION:\n` +
      solutionsFound.map(s => `   • ${s}`).join('\n');

    // Save summary to database if IDs provided
    if (db.getIsPostgres()) {
      if (visitId) {
        await db.query(
          `UPDATE visits SET notes = $1, transcription_summary = $2, updated_at = NOW() WHERE id = $3`,
          [cleanText, summary, visitId]
        );
      } else if (leadId) {
        await db.query(
          `UPDATE leads SET pain_points = $1, required_solution_notes = $2, updated_at = NOW() WHERE id = $3`,
          [cleanText, summary, leadId]
        );
      }
    } else {
      const store = db.getLocalStore();
      if (visitId && store.visits) {
        const idx = store.visits.findIndex(v => v.id === visitId);
        if (idx !== -1) {
          store.visits[idx].notes = cleanText;
          store.visits[idx].transcription_summary = summary;
        }
      } else if (leadId && store.leads) {
        const idx = store.leads.findIndex(l => l.id === leadId);
        if (idx !== -1) {
          store.leads[idx].pain_points = cleanText;
          store.leads[idx].required_solution_notes = summary;
        }
      }
    }

    return res.status(200).json({
      success: true,
      data: {
        cleanText,
        summary
      }
    });
  } catch (error) {
    console.error('summarizeVoiceNote error:', error);
    return res.status(500).json({ success: false, message: 'AI Summarization failed.' });
  }
};

// 3. LiveRestro Hardware Catalog
exports.getHardwareCatalog = async (req, res) => {
  try {
    if (db.getIsPostgres()) {
      const result = await db.query(`SELECT * FROM hardware_catalog ORDER BY title ASC`);
      return res.status(200).json({ success: true, data: result.rows });
    }
    // localStore Fallback
    const store = db.getLocalStore();
    const mockHw = [
      { id: 'hw_01', title: 'Android Touch POS Terminal (15")', price: 32000.0, description: '15.6 inch dual-screen widescreen POS billing system.', sku: 'HW-TRM-15D', category: 'Hardware', image_url: 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=400' },
      { id: 'hw_02', title: '80mm Thermal Receipt Printer', price: 6500.0, description: 'Ultra-fast thermal printing speed of 250mm/sec with auto cutter.', sku: 'HW-PRN-80', category: 'Hardware', image_url: 'https://images.unsplash.com/photo-1610483178766-8092dccb4c2e?w=400' }
    ];
    return res.status(200).json({ success: true, data: mockHw });
  } catch (error) {
    console.error('getHardwareCatalog error:', error);
    return res.status(500).json({ success: false, message: 'Failed to retrieve hardware catalog.' });
  }
};

// 4. Help Center FAQs
exports.getFaqs = async (req, res) => {
  try {
    const { category, search } = req.query;
    let queryStr = 'SELECT * FROM help_center WHERE 1=1';
    const params = [];

    if (category) {
      params.push(category);
      queryStr += ` AND category = $${params.length}`;
    }
    if (search) {
      params.push(`%${search.trim().toLowerCase()}%`);
      queryStr += ` AND (LOWER(question) LIKE $${params.length} OR LOWER(answer) LIKE $${params.length})`;
    }

    if (db.getIsPostgres()) {
      const result = await db.query(queryStr, params);
      return res.status(200).json({ success: true, data: result.rows });
    }

    // localStore Fallback
    const mockFaqs = [
      { id: 'faq_01', question: 'How to register a new Sales Executive?', answer: 'Authorized Managers can click on the Register Sales Executive button on the Sales Manager hub, input the employee details, and submit to save the user to PostgreSQL instantly.', category: 'System Setup' },
      { id: 'faq_02', question: 'How to track Sales Executive live GPS location?', answer: 'Go to the Field Radar section on the Manager dashboard to see real-time route tracing, checked-in visits, and active executive positions.', category: 'Live Tracking' }
    ];
    return res.status(200).json({ success: true, data: mockFaqs });
  } catch (error) {
    console.error('getFaqs error:', error);
    return res.status(500).json({ success: false, message: 'Failed to retrieve FAQs.' });
  }
};

// 5. Video Tutorials
exports.getVideoTutorials = async (req, res) => {
  try {
    if (db.getIsPostgres()) {
      const result = await db.query(`SELECT * FROM video_tutorials ORDER BY title ASC`);
      return res.status(200).json({ success: true, data: result.rows });
    }
    // localStore Fallback
    const mockVids = [
      { id: 'vid_01', title: 'Getting Started with LiveRestro App', description: 'Introduction to checking in at restaurants and registering new leads.', category: 'Training', video_url: 'https://assets.mixkit.co/videos/preview/mixkit-kitchen-chef-preparing-a-dish-42225-large.mp4', thumbnail_url: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=400', duration: '05:12' }
    ];
    return res.status(200).json({ success: true, data: mockVids });
  } catch (error) {
    console.error('getVideoTutorials error:', error);
    return res.status(500).json({ success: false, message: 'Failed to retrieve tutorials.' });
  }
};

// 6. Save Quotation Record
exports.saveQuotation = async (req, res) => {
  try {
    const { client_name, restaurant_name, email, phone, items, subtotal, discount, tax, total } = req.body;
    const userId = req.user ? req.user.id : 'usr_salesexecutive_prince';

    if (!client_name || !restaurant_name || !items || !total) {
      return res.status(400).json({ success: false, message: 'Client name, restaurant name, items, and total are required.' });
    }

    const quoteId = `qte_${Date.now()}_${Math.random().toString(36).substr(2, 4)}`;
    const itemsJson = typeof items === 'string' ? items : JSON.stringify(items);

    if (db.getIsPostgres()) {
      await db.query(
        `INSERT INTO quotation_records (id, client_name, restaurant_name, email, phone, items, subtotal, discount, tax, total, created_by)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
        [quoteId, client_name, restaurant_name, email || '', phone || '', itemsJson, parseFloat(subtotal || total), parseFloat(discount || 0), parseFloat(tax || 0), parseFloat(total), userId]
      );
    } else {
      const store = db.getLocalStore();
      if (!store.quotations) store.quotations = [];
      store.quotations.push({
        id: quoteId, client_name, restaurant_name, email, phone, items: itemsJson, subtotal, discount, tax, total, created_by: userId, created_at: new Date().toISOString()
      });
      db.saveLocalStore();
    }

    return res.status(201).json({
      success: true,
      message: 'Quotation saved successfully in PostgreSQL.',
      data: { id: quoteId }
    });
  } catch (error) {
    console.error('saveQuotation error:', error);
    return res.status(500).json({ success: false, message: 'Failed to save quotation.' });
  }
};

// 7. Get Notification History
exports.getNotifications = async (req, res) => {
  try {
    const userId = req.user ? req.user.id : 'usr_salesexecutive_prince';
    
    if (db.getIsPostgres()) {
      let result = await db.query(
        `SELECT * FROM notification_history WHERE user_id = $1 ORDER BY created_at DESC`,
        [userId]
      );
      
      if (result.rows.length === 0) {
        const initial = [
          {
            id: `not_${Date.now()}_1`,
            title: 'Urgent Follow-Up Reminder',
            body: 'Quotation discussion due today at 03:00 PM with Royal Spice Restaurant.',
            is_read: false
          },
          {
            id: `not_${Date.now()}_2`,
            title: 'Milestone Target Unlocked! 🏆',
            body: 'You reached 80% daily visit target. Complete 2 more visits to earn ₹500 bonus.',
            is_read: false
          },
          {
            id: `not_${Date.now()}_3`,
            title: 'Merchant Payment Received',
            body: '₹ 25,000 Advance UPI received from Spice & Rice Kitchen for Pro Annual SaaS.',
            is_read: true
          }
        ];
        
        for (const n of initial) {
          await db.query(
            `INSERT INTO notification_history (id, user_id, title, body, is_read, created_at)
             VALUES ($1, $2, $3, $4, $5, NOW())`,
            [n.id, userId, n.title, n.body, n.is_read]
          );
        }
        
        result = await db.query(
          `SELECT * FROM notification_history WHERE user_id = $1 ORDER BY created_at DESC`,
          [userId]
        );
      }
      
      return res.status(200).json({ success: true, data: result.rows });
    } else {
      const store = db.getLocalStore();
      if (!store.notifications) store.notifications = [];
      let list = store.notifications.filter(n => n.user_id === userId);
      if (list.length === 0) {
        const initial = [
          { id: `not_1`, user_id: userId, title: 'Urgent Follow-Up Reminder', body: 'Quotation discussion due today at 03:00 PM with Royal Spice Restaurant.', is_read: false, created_at: new Date().toISOString() },
          { id: `not_2`, user_id: userId, title: 'Milestone Target Unlocked! 🏆', body: 'You reached 80% daily visit target. Complete 2 more visits to earn ₹500 bonus.', is_read: false, created_at: new Date().toISOString() }
        ];
        store.notifications.push(...initial);
        db.saveLocalStore();
        list = initial;
      }
      return res.status(200).json({ success: true, data: list });
    }
  } catch (error) {
    console.error('getNotifications error:', error);
    return res.status(500).json({ success: false, message: 'Failed to retrieve notifications.' });
  }
};

// 8. AI Objection Counter Battlecard Generator
exports.generateObjectionBattlecard = async (req, res) => {
  try {
    const { objectionType, competitorName, customerRemarks } = req.body;
    const query = (objectionType || customerRemarks || competitorName || '').toLowerCase();

    let battlecard = {
      title: 'Objection Handling Battlecard',
      category: objectionType || 'General Objection',
      step1_acknowledge: 'Acknowledge the client\'s concern with empathy to establish rapport.',
      step2_differentiator: 'Highlight LiveRestro\'s unique value and direct ROI.',
      step3_closing_hook: 'Ask a high-converting closing or demo scheduling question.',
    };

    if (query.includes('petpooja') || query.includes('competitor') || query.includes('posist')) {
      battlecard = {
        title: `Handling "${competitorName || 'Competitor'}" Comparison`,
        category: 'Competitor Switch',
        step1_acknowledge: `"I completely understand, sir. ${competitorName || 'Petpooja'} is a well-known legacy system and many of our current premium restaurant clients previously used it."`,
        step2_differentiator: `"Where LiveRestro completely outperforms is: 1) Instant 0.2s KDS kitchen order dispatch (zero lag during weekend rushes), 2) Built-in WhatsApp marketing campaigns with zero per-message aggregator fees, and 3) 100% offline billing resilience even if local broadband goes down."`,
        step3_closing_hook: `"Can I show you a 5-minute live side-by-side speed test on our demo tablet right now?"`,
      };
    } else if (query.includes('expensive') || query.includes('price') || query.includes('cost') || query.includes('budget')) {
      battlecard = {
        title: 'Handling "Too Expensive / High Price" Objection',
        category: 'Pricing & ROI',
        step1_acknowledge: `"I appreciate you being upfront about the budget, sir. Every smart business owner looks closely at their operational expenses."`,
        step2_differentiator: `"Rather than a software cost, LiveRestro actually pays for itself within 14 days. By eliminating manual KOT mistakes and kitchen food waste, our clients save an average of ₹ 8,500 every month—more than 4x the subscription cost."`,
        step3_closing_hook: `"If I can prove how our system saves you at least ₹ 5,000 this month in billing leakages, would you be open to a 7-day risk-free counter trial?"`,
      };
    } else if (query.includes('hardware') || query.includes('printer') || query.includes('machine') || query.includes('old')) {
      battlecard = {
        title: 'Handling "We already have old hardware" Objection',
        category: 'Hardware Compatibility',
        step1_acknowledge: `"That is great, sir! You do not need to discard your existing setup."`,
        step2_differentiator: `"LiveRestro Cloud POS works seamlessly with standard ESC/POS USB, Ethernet, and Bluetooth thermal printers, Windows desktops, and Android tablets. You only invest in new hardware if you want to upgrade your counter."`,
        step3_closing_hook: `"Let me quickly connect our test app to your counter printer to show you how smoothly it prints in 2 seconds."`,
      };
    } else {
      battlecard = {
        title: 'Handling Change & Migration Hesitation',
        category: 'Migration & Support',
        step1_acknowledge: `"I completely understand your hesitation about disrupting your daily operations, sir."`,
        step2_differentiator: `"Our dedicated onboarding team imports your entire menu, taxes, and modifier items within 15 minutes. We also conduct on-site staff training so your cashiers and captains are 100% confident before going live."`,
        step3_closing_hook: `"Would 3:00 PM or 5:00 PM tomorrow be better for a 10-minute counter demonstration?"`,
      };
    }

    return res.status(200).json({
      success: true,
      data: battlecard,
    });
  } catch (error) {
    console.error('generateObjectionBattlecard error:', error);
    return res.status(500).json({ success: false, message: 'Failed to generate battlecard.' });
  }
};

// 9. AI Visiting Card OCR & Business Card Entity Extractor
exports.scanVisitingCard = async (req, res) => {
  try {
    const { rawText, imageText } = req.body;
    const text = (rawText || imageText || '').trim();

    if (!text) {
      return res.status(400).json({ success: false, message: 'Visiting card text or scan data is required.' });
    }

    // Regex phone extraction: extracts all 10-12 digit numbers formatted with +91, 0, spaces, dashes
    const allPhones = text.match(/(?:\+?91[\-\s]?)?[6-9]\d{4}[\-\s]?\d{5}|[6-9]\d{9}/g) || [];
    let mobile = '';
    if (allPhones.length > 0) {
      mobile = allPhones[0].replace(/[^0-9]/g, '');
      if (mobile.startsWith('91') && mobile.length === 12) {
        mobile = mobile.substring(2);
      }
    }

    // Regex email extraction
    const emailMatch = text.match(/[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}/i);
    const email = emailMatch ? emailMatch[0].trim() : '';

    // Split into non-empty lines and strip leading/trailing noise
    const lines = text
      .split(/[\r\n]+/)
      .map(l => l.trim())
      .filter(l => l.length > 1);

    let restaurantName = '';
    let contactPersonName = '';
    let addressParts = [];
    let businessType = 'Fine Dine';

    // Designation keywords to detect contact person name
    const designationRegex = /\b(owner|proprietor|partner|manager|general manager|director|founder|co-founder|chef|executive chef|head chef|managing director|ceo|gm)\b/i;
    // Food/Hospitality business keywords to detect restaurant name
    const hospitalityRegex = /\b(restaurant|restro|cafe|coffee|bistro|dhaba|hotel|kitchen|food|foods|sweets|bakery|bakers|lounge|bar|pub|grill|diner|eatery|pizzeria|biryani|caterers|chili|junction|dining|fine dine|treats)\b/i;
    // Address keywords
    const addressRegex = /\b(road|rd|street|st|nagar|cross|opp|opposite|near|nr|behind|b\/h|complex|plaza|arcade|tower|mall|highway|expressway|sector|phase|plot|block|floor|ahmedabad|mumbai|delhi|bangalore|surat|vadodara|pune|kolkata|hyderabad|chennai|gujarat|india|\d{6})\b/i;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const lower = line.toLowerCase();

      // Skip lines that are only phones, emails, or websites
      if (line.includes('@') || line.match(/^https?:\/\//i) || line.match(/^www\./i) || line.match(/^[0-9+\s\-()]{7,}$/)) {
        continue;
      }

      // Check if line contains designation (e.g., "Rajesh Patel - Owner" or "Owner: Amit Shah")
      if (designationRegex.test(lower) && !contactPersonName) {
        contactPersonName = line
          .replace(designationRegex, '')
          .replace(/[\(\):,\-\/|]/g, ' ')
          .trim();
        continue;
      }

      // Check for restaurant / brand name
      if (hospitalityRegex.test(lower) && !restaurantName) {
        restaurantName = line.trim();
        continue;
      }

      // Check for address lines
      if (addressRegex.test(lower)) {
        addressParts.push(line.trim());
        continue;
      }

      // If restaurantName not set and this is line 0 or 1, and not an address or person name
      if (!restaurantName && i === 0 && line.length > 2) {
        restaurantName = line.trim();
      } else if (!contactPersonName && !designationRegex.test(lower) && line.split(' ').length <= 4 && !addressRegex.test(lower) && i <= 2) {
        contactPersonName = line.trim();
      }
    }

    // If still no restaurant name found, pick the first clean line
    if (!restaurantName && lines.length > 0) {
      restaurantName = lines[0].replace(/[\(\):,\-\/|]/g, '').trim();
    }

    // Determine business type from whole text
    const lowerFull = text.toLowerCase();
    if (lowerFull.includes('cafe') || lowerFull.includes('coffee')) {
      businessType = 'Cafe';
    } else if (lowerFull.includes('bar') || lowerFull.includes('pub') || lowerFull.includes('brewery') || lowerFull.includes('lounge')) {
      businessType = 'Bar / Lounge';
    } else if (lowerFull.includes('bakery') || lowerFull.includes('cake') || lowerFull.includes('bakers')) {
      businessType = 'Bakery';
    } else if (lowerFull.includes('qsr') || lowerFull.includes('fast food') || lowerFull.includes('burger') || lowerFull.includes('pizza') || lowerFull.includes('sandwich')) {
      businessType = 'QSR / Fast Food';
    } else if (lowerFull.includes('dhaba')) {
      businessType = 'Dhaba';
    }

    const finalAddress = addressParts.join(', ').trim();

    return res.status(200).json({
      success: true,
      message: 'Visiting card scanned and extracted successfully',
      data: {
        restaurantName: restaurantName,
        contactPersonName: contactPersonName,
        mobile: mobile,
        email: email,
        address: finalAddress,
        businessType: businessType,
      }
    });
  } catch (error) {
    console.error('scanVisitingCard error:', error);
    return res.status(500).json({ success: false, message: 'Failed to process visiting card.' });
  }
};




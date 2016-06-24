do

  -- http://globalquran.com/contribute/signup.php
  local api_key = '?key=e2de2d3ed5c3b37b9d3bd6faeafa7891'

  local surah_name = { "Al-Fatihah", "Al-Baqarah", "Ali-Imran", "An-Nisaa'",
    "Al-Maaidah", "Al-An'aam", "Al-A'raaf", "Al-Anfaal", "At-Taubah", "Yunus",
    "Huud", "Yusuf", "Ar-Ra'd", "Ibrahim", "Al-Hijr", "An-Nahl", "Al-Israa'",
    "Al-Kahfi", "Maryam", "Thaahaa", "Al-Anbiyaa'", "Al-Hajj", "Al-Mukminuun",
    "An-Nuur", "Al-Furqaan", "Ash-Shu'araa", "An-Naml", "Al-Qashash",
    "Al-Ankabuut", "Ar-Ruum", "Luqman", "As-Sajdah", "Al-Ahzaab", "Saba'",
    "Faathir", "Yasiin", "As-Shaaffaat", "Shaad", "Az-Zumar", "Al-Ghaafir",
    "Fushshilat", "Asy-Syuura", "Az-Zukhruf", "Ad-Dukhaan", "Al-Jaatsiyah",
    "Al-Ahqaaf", "Muhammad", "Al-Fath", "Al-Hujuraat", "Qaaf", "Adz-Dzaariyat",
    "Ath-Thur", "An-Najm", "Al-Qamar", "Ar-Rahmaan", "Al-Waaqi'ah", "Al-Hadiid",
    "Al-Mujaadilah", "Al-Hasyr", "Al-Mumtahanah", "Ash-Shaff", "Al-Jumu'ah",
    "Al-Munaafiquun", "At-Taghaabuun", "Ath-Thaalaq", "At-Tahrim", "Al-Mulk",
    "Al-Qalam", "Al-Haaqqah", "Al-Ma'aarij", "Nuuh", "Al-Jin", "Al-Muzzammil",
    "Al-Muddatstsir", "Al-Qiyaamah", "Al-Insaan", "Al-Mursalaat", "An-Naba'",
    "An-Naazi'aat", "'Abasa", "At-Takwir", "Al-Infithaar", "Al-Mutaffifin",
    "Al-Insyiqaaq", "Al-Buruuj", "Ath-Thaariq", "Al-A'laa", "Al-Ghaashiyah",
    "Al-Fajr", "Al-Balad", "Asy-Syams", "Al-Lail", "Ad-Dhuhaa", "Alam Nasyrah",
    "At-Tiin", "Al-'Alaq", "Al-Qadr", "Al-Bayyinah", "Al-Zalzalah",
    "Al-'Aadiyaat", "Al-Qaari'ah", "At-Takaatsur", "Al-'Ashr", "Al-Humazah",
    "Al-Fiil", "Quraisy", "Al-Maa'uun", "Al-Kautsar", "Al-Kaafiruun", "An-Nashr",
    "Al-Lahab", "Al-Ikhlaas", "Al-Falaq", "An-Naas"}

  local function get_verse_num(verse)
    for i=1,6666 do
      if verse.quran['quran-simple'][tostring(i)] then
        return tostring(i)
      end
    end
  end

  local function get_trans(lang)
    if lang == 'ar' then
      trans = "ar.muyassar"
    elseif lang == 'az' then
      trans = "az.musayev"
    elseif lang == 'bg' then
      trans = "bg.theophanov"
    elseif lang == 'bn' then
      trans = "bn.bengali"
    elseif lang == 'bs' then
      trans = "bs.mlivo"
    elseif lang == 'cs' then
      trans = "cs.hrbek"
    elseif lang == 'de' then
      trans = "de.aburida"
    elseif lang == 'dv' then
      trans = "dv.divehi"
    elseif lang == 'en' then
      trans = "en.yusufali"
    elseif lang == 'es' then
      trans = "es.cortes"
    elseif lang == 'fa' then
      trans = "fa.makarem"
    elseif lang == 'fr' then
      trans = "fr.hamidullah"
    elseif lang == 'ha' then
      trans = "ha.gumi"
    elseif lang == 'hi' then
      trans = "hi.hindi"
    elseif lang == 'id' then
      trans = "id.indonesian"
    elseif lang == 'it' then
      trans = "it.piccardo"
    elseif lang == 'ja' then
      trans = "ja.japanese"
    elseif lang == 'ko' then
      trans = "ko.korean"
    elseif lang == 'ku' then
      trans = "ku.asan"
    elseif lang == 'ml' then
      trans = "ml.abdulhameed"
    elseif lang == 'ms' then
      trans = "ms.basmeih"
    elseif lang == 'nl' then
      trans = "nl.keyzer"
    elseif lang == 'no' then
      trans = "no.berg"
    elseif lang == 'pl' then
      trans = "pl.bielawskiego"
    elseif lang == 'pt' then
      trans = "pt.elhayek"
    elseif lang == 'ro' then
      trans = "ro.grigore"
    elseif lang == 'ru' then
      trans = "ru.kuliev"
    elseif lang == 'sd' then
      trans = "sd.amroti"
    elseif lang == 'so' then
      trans = "so.abduh"
    elseif lang == 'sq' then
      trans = "sq.ahmeti"
    elseif lang == 'sv' then
      trans = "sv.bernstrom"
    elseif lang == 'sw' then
      trans = "sw.barwani"
    elseif lang == 'ta' then
      trans = "ta.tamil"
    elseif lang == 'tg' then
      trans = "tg.ayati"
    elseif lang == 'th' then
      trans = "th.thai"
    elseif lang == 'tr' then
      trans = "tr.ozturk"
    elseif lang == 'tt' then
      trans = "tt.nugman"
    elseif lang == 'ug' then
      trans = "ug.saleh"
    elseif lang == 'ur' then
      trans = "ur.ahmedali"
    elseif lang == 'uz' then
      trans = "uz.sodik"
    elseif lang == 'zh' then
      trans = "zh.majian"
    else
      trans = lang
    end
    return trans
  end

  local function get_ayah(msg, surah, ayah, verse, lang)
    local gq = 'http://api.globalquran.com/ayah/'

    if lang then
      translation = get_trans(lang)
    end

    if verse then
      gq_ayah = gq .. verse .. '/quran-simple' .. api_key
      if lang then
        gq_lang = gq .. verse .. '/' .. translation .. api_key
      end
    end

    if surah and ayah then
      gq_ayah = gq .. surah .. ':' .. ayah .. '/quran-simple' .. api_key
      if lang then
        gq_lang = gq .. surah .. ':' .. ayah .. '/' .. translation .. api_key
      end
    end

    local res_ayah, code_ayah = http.request(gq_ayah)
    local jayah = json:decode(res_ayah)
    local verse_num = get_verse_num(jayah)

    if gq_lang then
      local res_lang, code_lang = http.request(gq_lang)
      local jlang = json:decode(res_lang)
      verse_trans = jlang.quran[translation][verse_num].verse
    end

    local surah_num = jayah.quran['quran-simple'][verse_num].surah
    local ayah_num = jayah.quran['quran-simple'][verse_num].ayah
    local gq_output = jayah.quran['quran-simple'][verse_num].verse .. '\n'
        .. (verse_trans or '').. '\n' .. '(' .. surah_name[surah_num] .. ':' .. ayah_num .. ')'

    reply_msg(msg.id, gq_output, ok_cb, true)
  end

  function run(msg, matches)
    if #matches == 1 then
      print('method #1')
      get_ayah(msg, nil, nil, matches[1], nil)
    end

    if #matches == 2 then
      print('method #2')
      get_ayah(msg, nil, nil, matches[1], matches[2])
    end

    if #matches == 3 then
      print('method #3')
      get_ayah(msg, matches[1], matches[3], nil, nil)
    end

    if #matches == 4 then
      print('method #4')
      get_ayah(msg, matches[1], matches[3], nil, matches[4])
    end
  end

  return {
    description = "Returns Al Qur'an verse.",
    usage = {
      '<code>!quran [verse number]</code>',
      "Returns Qur'an verse by its number.",
      '',
      '<code>!quran [verse number] [lang]</code>',
      "Returns Qur'an verse and its translation.",
      '',
      '<code>!quran [surah]:[ayah]</code>',
      "Returns Qur'an verse by surah and ayah number.",
      '',
      '<code>!quran [surah]:[ayah] [lang]</code>',
      "Returns Qur'an verse and its translation by surah and ayah number.",
      '',
      '<code>lang</code> is <a href="https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes">ISO 639-1 language code</a>.'
    },
    patterns = {
      '^!quran ([%d]+)$',
      '^!quran ([%d]+) (%g.*)$',
      '^!quran ([%d]+)(:)([%d]+)$',
      '^!quran ([%d]+)(:)([%d]+) (%g.*)$',
    },
    run = run
  }

end
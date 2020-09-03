require 'byebug'
require 'selenium-webdriver'
require 'jikan.rb'
require './animes'
require 'yaml'

#Configurações do webdriver
options = ::Selenium::WebDriver::Chrome::Options.new
options.add_argument('--headless')
@driver = Selenium::WebDriver.for(:chrome, options: options)
@wait = Selenium::WebDriver::Wait.new(:timeout => 10)

def scraper(nome_anime)

    qry = Jikan::Query.new #Iniciando API
    checando_requisicao = 1
    while checando_requisicao == 1
        begin
            qry = Jikan::Query.new
            anime_busca = qry.search(nome_anime, :anime)
            checando_requisicao = 0
            puts "passou."
        rescue
            checando_requisicao = 1
            puts "erro, tentando novamente."
        end
    end

    anime_busca = anime_busca.result
    anime_busca = anime_busca[0].id
    @driver.get "https://myanimelist.net/anime/" + anime_busca.to_s
    array_generos = capturar_generos
    anime = Anime.new(nome_anime, array_generos)
end

def capturar_generos
    lista_generos = []
    lista_site = @wait.until { @driver.find_element(:class => "borderClass").find_elements(:xpath => '//a[contains(@href,"genre")]') }
        lista_site.each do |generos|
            lista_generos.append(generos.text)
        end
        lista_generos
end

lista_animes = []

#Salvando lista em arquivo
File.open("lista.txt").each do |anime_nome|
    break if anime_nome.empty?
    lista_animes.append(scraper(anime_nome))
    sleep(4) #Requisito da API
end

serialized_list = Marshal.dump(lista_animes)
File.open('lista_objetos.txt', 'w') {|anime| anime.write(serialized_list)}

#Carregar lista salva em arquivo
lista_animes = Marshal.load(File.read('lista_objetos.txt'))
hash_table = {}
lista_animes.each do |anime|
    anime.generos.each do |genero|
        if hash_table.key?(genero)
            hash_table[genero] = hash_table[genero] + 1
        else
            hash_table[genero] = 1
        end
    end
end

#Salvar hash em arquivo YAML
File.write('animes_lista_hash.yaml', hash_table.sort_by {|_key, value| value}.to_h.to_yaml)
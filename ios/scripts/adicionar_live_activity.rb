# Adiciona ao Runner.xcodeproj a extensão RazorLiveActivity (lembrete do
# agendamento na Dynamic Island) e os arquivos Swift do lembrete no Runner.
#
# Pode rodar quantas vezes quiser: o que já existe fica como está.
# Uso (na pasta ios): ruby scripts/adicionar_live_activity.rb
require 'xcodeproj'

PASTA_IOS = File.expand_path('..', __dir__)
PROJETO = File.join(PASTA_IOS, 'Runner.xcodeproj')
NOME = 'RazorLiveActivity'
BUNDLE_APP = 'com.net.convertix.scissor'
# Bundle id do perfil "app_scissor_activity" que já existe no Codemagic.
BUNDLE_EXTENSAO = "#{BUNDLE_APP}.SessionLiveActivity"
IOS_MINIMO = '16.2'

project = Xcodeproj::Project.open(PROJETO)
runner = project.targets.find { |t| t.name == 'Runner' } or abort('Target Runner não encontrado')

def grupo(project, nome)
  project.main_group.children.find { |g| g.respond_to?(:path) && g.path == nome } ||
    project.main_group.new_group(nome, nome)
end

def arquivo(grupo, nome)
  grupo.files.find { |f| f.path == nome } || grupo.new_reference(nome)
end

def compilar(target, ref)
  return if target.source_build_phase.files_references.include?(ref)

  target.source_build_phase.add_file_reference(ref)
end

# Tipo compartilhado: entra no app e na extensão.
compartilhado = arquivo(grupo(project, 'Shared'), 'AgendamentoActivityAttributes.swift')

# Ponte com o Dart, só no app.
grupo_runner = project.main_group.children.find { |g| g.respond_to?(:path) && g.path == 'Runner' }
plugin = arquivo(grupo_runner, 'LembreteAgendamentoPlugin.swift')
compilar(runner, plugin)
compilar(runner, compartilhado)

# O app usa ActivityKit, que só existe do iOS 16.1 em diante; com o mínimo
# do app em 15, ele é ligado de forma opcional.
runner.build_configurations.each do |config|
  flags = Array(config.build_settings['OTHER_LDFLAGS'] || '$(inherited)')
  unless flags.include?('ActivityKit')
    config.build_settings['OTHER_LDFLAGS'] = flags + ['-weak_framework', 'ActivityKit']
  end
end

# Sem perfil de assinatura para a extensão, o app sai sem ela (e sem o
# lembrete na Dynamic Island) em vez de o build falhar.
if ENV['SEM_EXTENSAO'] == '1'
  project.save
  puts "Sem a extensão #{NOME}: só os arquivos do app foram adicionados"
  exit
end

extensao = project.targets.find { |t| t.name == NOME }

if extensao.nil?
  extensao = project.new_target(:app_extension, NOME, :ios, IOS_MINIMO, nil, :swift)
  puts "Target #{NOME} criado"
else
  puts "Target #{NOME} já existe, conferindo configuração"
end

grupo_extensao = grupo(project, NOME)
%w[RazorLiveActivityBundle.swift AgendamentoLiveActivity.swift].each do |nome|
  compilar(extensao, arquivo(grupo_extensao, nome))
end
arquivo(grupo_extensao, 'Info.plist')
# App Group: a extensão lê a foto do profissional que o app guardou.
arquivo(grupo_extensao, "#{NOME}.entitlements")
xcconfig = arquivo(grupo_extensao, "#{NOME}.xcconfig")
compilar(extensao, compartilhado)

extensao.build_configurations.each do |config|
  config.base_configuration_reference = xcconfig
  config.build_settings.merge!(
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'PRODUCT_BUNDLE_IDENTIFIER' => BUNDLE_EXTENSAO,
    'INFOPLIST_FILE' => "#{NOME}/Info.plist",
    'CODE_SIGN_ENTITLEMENTS' => "#{NOME}/#{NOME}.entitlements",
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'IPHONEOS_DEPLOYMENT_TARGET' => IOS_MINIMO,
    'SWIFT_VERSION' => '5.0',
    'TARGETED_DEVICE_FAMILY' => '1,2',
    'SKIP_INSTALL' => 'YES',
    'APPLICATION_EXTENSION_API_ONLY' => 'YES',
    'CODE_SIGN_STYLE' => 'Automatic',
    'MARKETING_VERSION' => '$(FLUTTER_BUILD_NAME)',
    'CURRENT_PROJECT_VERSION' => '$(FLUTTER_BUILD_NUMBER)',
    'LD_RUNPATH_SEARCH_PATHS' => [
      '$(inherited)',
      '@executable_path/Frameworks',
      '@executable_path/../../Frameworks',
    ],
  )
end

runner.add_dependency(extensao) unless runner.dependencies.any? { |d| d.target == extensao }

# Copia a extensão para dentro do app (pasta PlugIns).
embed = runner.copy_files_build_phases.find { |f| f.name == 'Embed Foundation Extensions' }
if embed.nil?
  embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
  embed.symbol_dst_subfolder_spec = :plug_ins
end
unless embed.files_references.include?(extensao.product_reference)
  arquivo_embed = embed.add_file_reference(extensao.product_reference)
  arquivo_embed.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

# A cópia precisa vir antes dos scripts do Flutter (Thin Binary), senão o
# Xcode acusa "Cycle inside Runner".
fases = runner.build_phases
fases.delete(embed)
primeiro_script = fases.index { |f| f.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) && f.name.to_s.include?('Thin Binary') }
fases.insert(primeiro_script || fases.length, embed)

project.save
puts "Pronto: #{NOME} (#{BUNDLE_EXTENSAO}) embutido no Runner"

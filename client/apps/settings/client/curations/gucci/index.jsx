import PropTypes from 'prop-types'
import React from 'react'
import DropDownItem from 'client/components/drop_down/index.jsx'
import { SaveButton } from '../components/save_button.jsx'
import { SectionAdmin } from './components/section.jsx'
import { SeriesAdmin } from './components/series.jsx'

export class GucciAdmin extends React.Component {
  constructor (props) {
    super(props)
    this.state = {
      curation: props.curation,
      isSaved: true,
      activeSection: null
    }
  }

  setActiveSection = (i) => {
    i = i === this.state.activeSection ? null : i
    this.setState({activeSection: i})
  }

  save = () => {
    this.state.curation.save({}, {
      success: () => this.setState({ isSaved: true }),
      error: error => this.setState({ isSaved: false })
    })
  }

  onChange = (key, value) => {
    const newCuration = this.state.curation.clone()
    newCuration.set(key, value)

    this.setState({
      curation: newCuration,
      isSaved: false
    })
  }

  onChangeSection = (key, value, index) => {
    const sections = this.state.curation.get('sections')
    sections[index][key] = value
    this.onChange('sections', sections)
  }

  render () {
    const { activeSection, curation, isSaved } = this.state

    return (
      <div className='gucci-admin curation--admin-container'>
        {curation.get('sections').map((section, index) =>
          <div
            className='gucci-admin__section'
            data-active={activeSection === index}
            key={`gucci-admin-${index}`}>
            <DropDownItem
              active={index === this.state.activeSection}
              index={index}
              onClick={() => this.setActiveSection(index)}
              title={section.title}>
              {activeSection === index &&
                <div className='gucci-admin__section-inner'>
                  <SectionAdmin
                    section={section}
                    onChange={(key, value) => this.onChangeSection(key, value, index)} />
                </div>
              }
            </DropDownItem>
          </div>
        )}
        <div className='gucci-admin__series'>
          <SeriesAdmin
            curation={curation}
            onChange={this.onChange} />
        </div>
        <SaveButton
          onSave={this.save}
          isSaved={isSaved} />
      </div>
    )
  }
}

GucciAdmin.propTypes = {
  curation: PropTypes.object.isRequired
}

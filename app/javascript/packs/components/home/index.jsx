import React, { Component } from 'react'
import { connect } from 'react-redux'
import moment from 'moment'
import { Page, Layout, Filters, FormLayout, Card, Toast, Loading, Tabs, DataTable, Checkbox, Badge, Pagination, Link, TextStyle, SkeletonBodyText, Stack, Button, TextField, ButtonGroup, DropZone, Thumbnail, Caption, SettingToggle } from '@shopify/polaris'

import _ from 'lodash'

import {
    togglePreloader,
  } from '../../actions/preloader'

  import {
    loadProducts,
  } from '../../actions/product'

class Home extends Component {

    constructor(props) {
        super(props)
        this.state = {
            loading: true,
            products: [],
            per_page: 10,
            page_number: 1,
            originalProducts: []
        }
    }

    componentDidMount () {
        this.loadProducts()
    }

    loadProducts = () => {
        const { page_number, per_page } = this.state
        this.setState({loading: true})
        this.props.loadProducts({
            page_number,
            per_page,
            cb: data => {
                console.log(data)
                this.setState({
                    loading: false,
                    products: data.products,
                    originalProducts: JSON.parse(JSON.stringify(data.products))
                })
            }
        })
        
    }

    handlePage = action => () => {
        let page_number = action === 'prev' ? this.state.page_number - 1 : this.state.page_number + 1
        this.setState({page_number}, () => {
          this.loadProducts()
        })
    }

    render () {
        const { loading, products } = this.state
        const { hasPrevious, hasNext, product_counts } = this.props

        // const rows = products.map(product => {
        //     return [
        //       <img
        //           source={product.image}
        //           product name={product.name}
        //         />,
        //       <TextStyle>
        //         {product.name}
        //       </TextStyle>,
        //       <Link
        //         url={`/products/${product.id}`}
        //       >
        //         Edit Image
        //       </Link>
        //     ]
        // })

        return (
            <Page title="Dashboard">
                {loading && <Loading />}
                <Layout>
                    <Layout.Section>
                        <Card>
                            <Card.Section>
                                <Card.Subsection>
                                    {loading && <SkeletonBodyText />}
                                </Card.Subsection>
                            </Card.Section>
                        </Card>
                    </Layout.Section>
                </Layout>
            </Page>  
        )
    }
}

const mapStateToProps = state => ({
    preloader: state.preloader,
    products: state.product.products,
    hasNext: state.product.hasNext,
    hasPrevious: state.product.hasPrevious,
    product_counts: state.product.product_counts
  })
  
  const mapDispatchToProps = {
    togglePreloader,
    loadProducts
  }
  
  export default connect(
    mapStateToProps,
    mapDispatchToProps
  )(Home)